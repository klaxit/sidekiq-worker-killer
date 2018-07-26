require "get_process_mem"
require "sidekiq"
require "sidekiq/util"

module Sidekiq
  # Sidekiq server middleware. Kill worker when the RSS memory exceeds limit
  # after a given grace time.
  class WorkerKiller
    include Sidekiq::Util

    MUTEX = Mutex.new

    def initialize(options = {})
      @max_rss         = (options[:max_rss]         || 0)
      @grace_time      = (options[:grace_time]      || 15 * 60)
      @shutdown_wait   = (options[:shutdown_wait]   || 30)
      @kill_signal     = (options[:kill_signal]     || "SIGKILL")
    end

    def call(_worker, _job, _queue)
      yield
      # Skip if the max RSS is not exceeded
      return unless @max_rss > 0 && current_rss > @max_rss
      GC.start(full_mark: true, immediate_sweep: true)
      return unless @max_rss > 0 && current_rss > @max_rss
      # Launch the shutdown process
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
      sleep(@grace_time)

      warn "sending SIGTERM to #{identity}"
      signal("SIGTERM", pid)

      warn "waiting #{@shutdown_wait} seconds before sending " \
            "#{@kill_signal} to #{identity}"
      sleep(@shutdown_wait)

      warn "sending #{@kill_signal} to #{identity}"
      signal(@kill_signal, pid)
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
end
