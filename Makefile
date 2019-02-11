.PHONY: test

console:
	irb -I lib -r sidekiq/worker_killer

test:
	bundle exec rspec spec

lint:
	bundle exec rubocop
