.PHONY: test

console:
	irb -I lib -r sidekiq/worker_killer
