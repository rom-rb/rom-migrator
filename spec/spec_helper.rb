# encoding: utf-8

begin
  require "hexx-suit"
  Hexx::Suit.load_metrics_for(self)
rescue LoadError
  require "hexx-rspec"
  Hexx::RSpec.load_metrics_for(self)
end

# Loads the code under test
require "rom-migrator"

# Loads gems-specific shared examples
require "transproc/rspec"
require "immutability/rspec"

# Loads some helpers and shared contexts
require "timecop"
require "support/memfs"
require "shared/custom_template"
require "shared/migrations"

# This is necessary because some mutations can provide circular dependencies
if ENV["MUTANT"]
  RSpec.configure do |config|
    config.around { |example| Timeout.timeout(0.5, &example) }
  end
end

# Path to gem's root used in some specs
ROOT = File.expand_path("../..", __FILE__)
