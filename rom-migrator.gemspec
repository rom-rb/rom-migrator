$:.push File.expand_path("../lib", __FILE__)
require "rom/migrator/version"

Gem::Specification.new do |gem|

  gem.name        = "rom-migrator"
  gem.version     = ROM::Migrator::VERSION.dup
  gem.author      = "Andrew Kozin"
  gem.email       = "andrew.kozin@gmail.com"
  gem.homepage    = "https://github.com/nepalez/rom-migrator"
  gem.summary     = "Base class for ROM migrators"
  gem.license     = "MIT"

  gem.files            = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  gem.test_files       = Dir["spec/**/*.rb"]
  gem.extra_rdoc_files = Dir["README.md", "LICENSE"]
  gem.require_paths    = ["lib"]

  gem.required_ruby_version = "~> 1.9", ">= 1.9.3"

  gem.add_runtime_dependency "immutability", "~> 0.0", ">= 0.0.5"
  gem.add_runtime_dependency "rom", "~> 0.9", ">= 0.9.1"

  gem.add_development_dependency "hexx-rspec", "~> 0.5"
  gem.add_development_dependency "inflecto", "~> 0.0", ">= 0.0.2"
  gem.add_development_dependency "memfs", "~> 0.5"
  gem.add_development_dependency "timecop", "~> 0.8"

end # Gem::Specification
