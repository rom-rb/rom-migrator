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

# Loads some helpers and shared contexts
require "support/memfs"
require "shared/custom_template"
require "shared/migrations"
