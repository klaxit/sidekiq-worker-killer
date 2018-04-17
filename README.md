
# sidekiq-worker-killer
[![CircleCI](https://circleci.com/gh/klaxit/sidekiq-worker-killer/tree/master.svg?style=shield&circle-token=9979a41b6831e6f65749638b923643b86e5fc580)](https://circleci.com/gh/klaxit/sidekiq-worker-killer/tree/master)

[Sidekiq](https://github.com/mperham/sidekiq) is probably the best background processing framework today. At the same time, memory leaks are very hard to tackle in Ruby and we often find ourselves with growing memory consumption.

Highly inspired by [Gitlab Sidekiq MemoryKiller](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/lib/gitlab/sidekiq_middleware/shutdown.rb) and [Noxa Sidekiq killer](https://github.com/Noxa/sidekiq-killer).

## Install
Use [Bundler](http://bundler.io/)
```
gem "sidekiq-worker-killer", git: "https://github.com/klaxit/sidekiq-worker-killer"
```

## Usage

Add this to your Sidekiq configuration.

```
Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Sidekiq::WorkerKiller, max_rss: 250
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
