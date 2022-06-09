$LOAD_PATH.push File.expand_path("lib", __dir__)
require "sidekiq/worker_killer/version"

Gem::Specification.new do |s|
  s.name        = "sidekiq-worker-killer"
  s.version     = Sidekiq::WorkerKiller::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Cyrille Courtiere"]
  s.email       = ["dev@klaxit.com"]
  s.homepage    = "http://github.com/klaxit/sidekiq-worker-killer"
  s.summary     = "Sidekiq worker killer"

  s.files = `git ls-files -- lib/*`.split("\n")
  s.files += %w(README.md)
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = "lib"

  s.add_runtime_dependency("get_process_mem", "~> 0.2.1")
  s.add_runtime_dependency("sidekiq", ">= 5")

  s.add_development_dependency("rspec", "~> 3.5")
  s.add_development_dependency("rubocop", "~> 0.49.1")
  s.add_development_dependency("appraisal")
end
