
# sidekiq-worker-killer
[![Gem Version](https://badge.fury.io/rb/sidekiq-worker-killer.svg)](https://badge.fury.io/rb/sidekiq-worker-killer)
[![CircleCI](https://circleci.com/gh/klaxit/sidekiq-worker-killer.svg?style=shield&circle-token=:circle-token)](https://circleci.com/gh/klaxit/sidekiq-worker-killer)

[Sidekiq](https://github.com/mperham/sidekiq) is probably the best background processing framework today. At the same time, memory leaks are very hard to tackle in Ruby and we often find ourselves with growing memory consumption. Instead of spending herculean effort fixing leaks, why not kill your processes when they got to be too large?

Highly inspired by [Gitlab Sidekiq MemoryKiller](https://gitlab.com/gitlab-org/gitlab-foss/-/blob/39c1731a53d1014eab7c876d70632b1abf738712/lib/gitlab/sidekiq_middleware/shutdown.rb) and [Noxa Sidekiq killer](https://github.com/Noxa/sidekiq-killer).

---
**NOTE**

This gem needs to get the used memory of the Sidekiq process. For
this we use [GetProcessGem](https://github.com/schneems/get_process_mem),
but be aware that if you are running Sidekiq in Heroku(or any container) the
memory usage will
[not be accurate](https://github.com/schneems/get_process_mem/issues/7).

---

quick-refs: [install](#install) | [usage](#usage) | [available options](#available-options) | [development](#development)

## Install
Use [Bundler](http://bundler.io/)
```ruby
gem "sidekiq-worker-killer"
```

## Usage

Add this to your Sidekiq configuration.

```ruby
require 'sidekiq/worker_killer'

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Sidekiq::WorkerKiller, max_rss: 480
  end
end
```

## Available options

The following options can be overridden.

| Option | Defaults | Description |
| ------- | ------- | ----------- |
| max_rss | 0 MB (disabled) | Max RSS in megabytes used by the Sidekiq process. Above this, shutdown will be triggered. |
| grace_time | 900 seconds | When shutdown is triggered, the Sidekiq process will not accept new job and wait at most 15 minutes for running jobs to finish. If Float::INFINITY specified, will wait forever. |
| shutdown_wait | 30 seconds | When the grace time expires, still running jobs get 30 seconds to stop. After that, kill signal is triggered. |
| kill_signal | SIGKILL | Signal to use to kill Sidekiq process if it doesn't stop. |
| gc | true | Try to run garbage collection before Sidekiq process stops in case of exceeded max_rss. |
| skip_shutdown_if | proc {false} | Executes a block of code after max_rss exceeds but before requesting shutdown. |
| on_shutdown | nil | Executes a block of code before just before requesting shutdown. This can be used to send custom logs or metrics to external services. |

*skip_shutdown_if* is expected to return anything other than `false` or `nil` to skip shutdown.

```ruby
require 'sidekiq/worker_killer'

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Sidekiq::WorkerKiller, max_rss: 480, skip_shutdown_if: ->(worker, job, queue) do
      worker.to_s == 'LongWorker'
    end
  end
end
```

## Development

Pull Requests are very welcome!

There are tasks that may help you along the way in a makefile:

```bash
make console # Loads the whole stack in an IRB session.
make test # Run tests.
make lint # Run rubocop linter.
```
Please make sure that you have tested your code carefully before opening a PR, and make sure as well that you have no style issues.

## Authors

See the list of [contributors](https://github.com/klaxit/sidekiq-worker-killer/contributors) who participated in this project.

## License

Please see [LICENSE](https://github.com/klaxit/sidekiq-worker-killer/blob/master/LICENSE)
