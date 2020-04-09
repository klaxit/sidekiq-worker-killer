require "get_process_mem"
require "sidekiq"
require "sidekiq/util"
require "sidekiq/api"

# Sidekiq server middleware. Kill worker when the RSS memory exceeds limit
# after a given grace time.
class Sidekiq::WorkerKiller
  include Sidekiq::Util

  MUTEX = Mutex.new

  def initialize(options = {})
    @max_rss         = options.fetch(:max_rss, 0)
    @grace_time      = options.fetch(:grace_time, 15 * 60)
    @shutdown_wait   = options.fetch(:shutdown_wait, 30)
    @kill_signal     = options.fetch(:kill_signal, "SIGKILL")
    @gc              = options.fetch(:gc, true)
    @skip_shutdown   = options.fetch(:skip_shutdown_if, Proc.new { false })
  end

  def call(worker, job, queue)
    yield
    # Skip if the max RSS is not exceeded
    return unless @max_rss > 0
    return unless current_rss > @max_rss
    GC.start(full_mark: true, immediate_sweep: true) if @gc
    return unless current_rss > @max_rss
    if @skip_shutdown.respond_to?(:call) && @skip_shutdown.call(worker, job, queue)
      warn "current RSS #{current_rss} exceeds maximum RSS #{@max_rss}, however shutdown will be ignored"
      return
    end

    warn "current RSS #{current_rss} of #{identity} exceeds " \
         "maximum RSS #{@max_rss}"
    request_shutdown
  end

  private

  def request_shutdown
    # In another thread to allow undelying job to finish
    Thread.new do
      # Only if another thread is not already
      # shutting down the Sidekiq process
      shutdown if MUTEX.try_lock
    end
  end

  def shutdown
    warn "sending quiet to #{identity}"
    sidekiq_process.quiet!

    sleep(5) # gives Sidekiq API 5 seconds to update ProcessSet

    warn "shutting down #{identity} in #{@grace_time} seconds"
    wait_job_finish_in_grace_time

    warn "stopping #{identity}"
    sidekiq_process.stop!

    warn "waiting #{@shutdown_wait} seconds before sending " \
          "#{@kill_signal} to #{identity}"
    sleep(@shutdown_wait)

    warn "sending #{@kill_signal} to #{identity}"
    ::Process.kill(@kill_signal, ::Process.pid)
  end

  def wait_job_finish_in_grace_time
    start = Time.now
    sleep(1) until grace_time_exceeded?(start) || jobs_finished?
  end

  def grace_time_exceeded?(start)
    return false if @grace_time == Float::INFINITY

    start + @grace_time < Time.now
  end

  def jobs_finished?
    sidekiq_process.stopping? && sidekiq_process["busy"].zero?
  end

  def current_rss
    ::GetProcessMem.new.mb
  end

  def sidekiq_process
    Sidekiq::ProcessSet.new.find { |process|
      process["identity"] == identity
    } || raise("No sidekiq worker with identity #{identity} found")
  end

  def warn(msg)
    Sidekiq.logger.warn(msg)
  end
end
