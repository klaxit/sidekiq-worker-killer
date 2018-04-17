
# sidekiq-worker-killer
[![Gem Version](https://badge.fury.io/rb/sidekiq-worker-killer.svg)](https://badge.fury.io/rb/sidekiq-worker-killer)
[![CircleCI](https://circleci.com/gh/klaxit/sidekiq-worker-killer.svg?style=shield&circle-token=:circle-token)](https://circleci.com/gh/klaxit/sidekiq-worker-killer)

[Sidekiq](https://github.com/mperham/sidekiq) is probably the best background processing framework today. At the same time, memory leaks are very hard to tackle in Ruby and we often find ourselves with growing memory consumption.

Highly inspired by [Gitlab Sidekiq MemoryKiller](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/lib/gitlab/sidekiq_middleware/shutdown.rb) and [Noxa Sidekiq killer](https://github.com/Noxa/sidekiq-killer).

## Install
Use [Bundler](http://bundler.io/)
```
gem "sidekiq-worker-killer"
```

## Usage

Add this to your Sidekiq configuration.

```
Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Sidekiq::WorkerKiller, max_rss: 480
  end
end
```

# Available options

The following options can be overrided.

| Option | Defaults | Description |
| ------- | ------- | ----------- |
| max_rss | 0 MB (disabled) | Max RSS in megabytes.                                              |
| grace_time | 900 seconds | When a shutdown is triggered, the Sidekiq process will keep working normally for another 15 minutes. |
| shutdown_wait | 30 seconds | When the grace time expires, existing jobs get 30 seconds to finish. After that, shutdown signal is triggered.  |
| shutdown_signal | SIGKILL | Signal to use to shutdown sidekiq |

## Authors

See the list of [contributors](https://github.com/klaxit/sidekiq-worker-killer/contributors) who participated in this project.

## License

Please see LICENSE
