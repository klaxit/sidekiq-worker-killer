module Sidekiq
  # Sidekiq server middleware. Kill worker when the RSS memory exceeds limit
  # after a given grace time.
  class WorkerKiller
    MUTEX = Mutex.new

    def initialize(options = {})
      @max_rss         = (options[:max_rss]         || 0)
      @grace_time      = (options[:grace_time]      || 15 * 60)
      @shutdown_wait   = (options[:shutdown_wait]   || 30)
      @shutdown_signal = (options[:shutdown_signal] || "SIGKILL")
    end

    def call(worker, _job, _queue)
      yield
      # Skip if the max RSS is not exceeded
      return unless @max_rss > 0 && current_rss > @max_rss
      # Perform kill
      perform_kill(worker)
    end

    private

    def perform_kill(worker)
      # In another thread to allow undelying job to finish
      Thread.new do
        # Return if another thread is already waiting to shut Sidekiq down
        return unless MUTEX.try_lock

        # Perform the killing process
        worker_ref = "PID #{pid} - Worker #{worker.class}"

        warn "current RSS #{current_rss} exceeds maximum RSS #{@max_rss}"
        warn "this thread will shut down #{worker_ref} in " \
             "#{@grace_time} seconds"
        sleep(@grace_time)

        warn "sending SIGTERM to #{worker_ref}"
        kill("SIGTERM", pid)

        warn "waiting #{@shutdown_wait} seconds before sending " \
             "#{@shutdown_signal} to #{worker_ref}"
        sleep(@shutdown_wait)

        warn "sending #{@shutdown_signal} to #{worker_ref}"
        kill(@shutdown_signal, pid)
      end
    end

    def current_rss
      GetProcessMem.new.mb
    end

    def kill(signal, pid)
      ::Process.kill(signal, pid)
    end

    def pid
      @pid ||= ::Process.pid
    end

    def warn(msg)
      Sidekiq.logger.warn(msg)
    end
  end
end
