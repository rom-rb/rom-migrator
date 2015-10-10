# encoding: utf-8

require "bundler/setup"
require "rubygems"

# Loads bundler tasks
Bundler::GemHelper.install_tasks

# Loads the Hexx::RSpec and its tasks
begin
  require "hexx-suit"
  Hexx::Suit.install_tasks
rescue LoadError
  require "hexx-rspec"
  Hexx::RSpec.install_tasks
end

desc "Runs specs and check coverage"
task :default do
  system "bundle exec rake test:coverage:run"
end

desc "Runs mutation metric for testing"
task :mutant do
  system "MUTANT=true mutant -r rom-migrator --use rspec ROM::Migrator*" \
         " --fail-fast"
end

desc "Exhort all evils"
task :exhort do
  system "MUTANT=true mutant -r rom-migrator --use rspec ROM::Migrator*"
end

desc "Runs all the necessary metrics before making a commit"
task prepare: %w(exhort check:inch check:rubocop check:fu)
