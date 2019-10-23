require "get_process_mem"
require "sidekiq"
require "sidekiq/util"

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
    @skip_shutdown   = options.fetch(:skip_shutdown_if, nil)
  end

  def call(worker, job, queue)
    yield
    # Skip if the max RSS is not exceeded
    return unless @max_rss > 0
    return unless current_rss > @max_rss
    GC.start(full_mark: true, immediate_sweep: true) if @gc
    return unless current_rss > @max_rss
    if @skip_shutdown && @skip_shutdown.call(worker, job, queue)
      warn "#{worker.class} exceeds maximum RSS #{@max_rss}, however shutdown will be ignored"
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
    warn "sending #{quiet_signal} to #{identity}"
    signal(quiet_signal, pid)

    warn "shutting down #{identity} in #{@grace_time} seconds"
    wait_job_finish_in_grace_time

    warn "sending SIGTERM to #{identity}"
    signal("SIGTERM", pid)

    warn "waiting #{@shutdown_wait} seconds before sending " \
          "#{@kill_signal} to #{identity}"
    sleep(@shutdown_wait)

    warn "sending #{@kill_signal} to #{identity}"
    signal(@kill_signal, pid)
  end

  def wait_job_finish_in_grace_time
    start = Time.now
    loop do
      break if grace_time_exceeded?(start)
      break if no_jobs_on_quiet_processes?
      sleep(1)
    end
  end

  def grace_time_exceeded?(start)
    return false if @grace_time == Float::INFINITY

    start + @grace_time < Time.now
  end

  def no_jobs_on_quiet_processes?
    Sidekiq::ProcessSet.new.each do |process|
      return false if process["busy"] != 0 && process["quiet"] == "true"
    end
    true
  end

  def current_rss
    ::GetProcessMem.new.mb
  end

  def signal(signal, pid)
    ::Process.kill(signal, pid)
  end

  def pid
    ::Process.pid
  end

  def identity
    "#{hostname}:#{pid}"
  end

  def quiet_signal
    if Gem::Version.new(Sidekiq::VERSION) >= Gem::Version.new("5.0")
      "TSTP"
    else
      "USR1"
    end
  end

  def warn(msg)
    Sidekiq.logger.warn(msg)
  end
end
