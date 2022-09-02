.PHONY: test

console:
	irb -I lib -r sidekiq/worker_killer

bundle:
	bundle pack
	bundle config set cache_all true
	bundle config set --local path '.bundle/vendor'
	bundle check || bundle install
	bundle exec appraisal install
	bundle exec appraisal bundle install

test:
	bundle exec appraisal rspec spec

lint:
	bundle exec rubocop
