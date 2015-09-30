[WIP] ROM::Migrator
===================

[![Gem Version](https://img.shields.io/gem/v/rom-migrator.svg?style=flat)][gem]
[![Build Status](https://img.shields.io/travis/rom-rb/rom-migrator/master.svg?style=flat)][travis]
[![Dependency Status](https://img.shields.io/gemnasium/rom-rb/rom-migrator.svg?style=flat)][gemnasium]
[![Code Climate](https://img.shields.io/codeclimate/github/rom-rb/rom-migrator.svg?style=flat)][codeclimate]
[![Coverage](https://img.shields.io/coveralls/rom-rb/rom-migrator.svg?style=flat)][coveralls]
[![Inline docs](http://inch-ci.org/github/rom-rb/rom-migrator.svg)][inch]

Base class for [ROM][rom] migrators.

Usage
-----

### When creating Custom Adapter

You are supposed to make 4 additional steps to provide adapter with a migrator:

- [load the gem](#load-the-gem)
- [provide the migrator](#provide-the-migrator)
- [provide the base migration](#provide-the-base-migration)
- [add rake task](#add-rake-task)

#### Load the Gem

Install and require the gem. It is not loaded by default because there is a bunch of adapters that doesn't need mingrators.

```ruby
# lib/rom-custom_adapter.rb
require "rom"
require "rom-migrator"
```

#### Provide the Migrator

Subclass the migrator from `ROM::Migrator` and define the `adapter` explicitly:

```ruby
# lib/rom-custom_adapter/migrator.rb
module ROM::CustomAdapter
  class Migrator < ROM::Migrator
    adapter :custom_adapter
  end
end
```
```ruby
# spec/unit/rom-custom_adapter/migrator_spec.rb
describe ROM::CustomAdapter::Migrator
  let(:migrator) { described_class.new }

  describe "#adapter" do
    subject { migrator.adapter }

    it { is_expected.to eql :custom_adapter }
  end
end
```

Then you MUST define 3 adapter-specific methods, that allow migrator to register/unregister applied migration in a persistence, and find the numbers of migrations being applied:

```ruby
# lib/rom-custom_adapter/migrator.rb
module ROM::CustomAdapter
  class Migrator < ROM::Migrator
    # ...

    # Registers the number of migration being applied
    #
    # @param [String] number
    #
    # @return [undefined]
    #
    def register(number)
      # ...adapter-specific code
    end

    # Unregisters the number of migration being rolled back
    #
    # @param [String] number
    #
    # @return [undefined]
    #
    def unregister(number)
      # ...adapter-specific code
    end

    # Returns the array of registered numbers of applied migrations
    #
    # @return [Array<String>]
    #
    def registered
      # ...adapter-specific code
    end
  end
end
```
```ruby
# spec/unit/rom-custom_adapter/migrator_spec.rb
describe ROM::CustomAdapter::Migrator
  let(:migrator) { described_class.new }

  describe "#registered?" do
    subject { migrator.registered? "1" }

    it { is_expected.to eql false }
  end

  describe "#register" do
    subject { migrator.register "1" }

    it "registers the migration" do
      expect { subject }.to change { migrator.registered? "1" }.to true
    end
  end

  describe "#unregister" do
    subject { migrator.unregister "1" }

    it "unregisters the migration" do
      migrator.register "1"
      expect { subject }.to change { migrator.registered? "1" }.to false
    end
  end
end
```

Customize the default path to migrations. By default it is set to `"db/migrate"`.

```ruby
# lib/rom-custom_adapter/migrator.rb
module ROM::CustomAdapter
  class Migrator < ROM::Migrator
    # ...
    default_path "custom/migrate"
    # ...
  end
end
```
```ruby
# spec/unit/rom-custom_adapter/migrator_spec.rb
describe ROM::CustomAdapter::Migrator do
  let(:migrator) { described_class.new }

  describe "#default_path" do
    subject { migrator.default_path }

    it { is_expected.to eql "custom/migrate" }
  end
end
```

Reload `#next_migration_number`, that defines the number of the migration being generated.
By default the number is a timestamp in 'YYYYmmddHHMMSS' format.

Notice, that migrator will order migrations by *stringified* numbers in the *ascending* order. That's why stringified output of the method MUST be greater than its stringified argument. See the inline comment below for the method's contract:

```ruby
# lib/rom-custom_adapter/migrator.rb
module ROM::CustomAdapter
  class Migrator < ROM::Migrator
    # ...

    # Returns the number for the next migration in a sequential order
    #
    # @param [String, nil] last_number The number of the last existing migration
    #
    # @return [#to_s]
    #
    def next_migration_number(last_number)
      last_number.to_i + 1
    end
    # ...
  end
end
```
```ruby
# spec/unit/rom-custom_adapter/migrator_spec.rb
describe ROM::CustomAdapter::Migrator do
  let(:migrator) { described_class.new }

  describe "#next_migration_number" do
    subject { migrator.next_migration_number(last_number) }

    context "nil value" do
      let(:last_number) { nil }

      it { is_expected.to eql 1 }
    end

    context "string value" do
      let(:last_number) { "2" }

      it { is_expected.to eql 3 }
    end
  end
end
```

Customize the template, that will be used by the generator of migrations. The default template is defined by the `rom-migrator` gem.

To add custom template you have to:
- create the template
- set the path to that template in a migrator 

The tempate should be ERB file where 2 variables are available:
- `@name` for the camelized name of the migration
- `@base` for the camelized name of the adapter-specific migration

```
# lib/rom-custom_adapter/migration.erb
class <%= @name %> < <%= @base %>
  def up
  end

  def down
  end
end
```

```ruby
# lib/rom-custom_adapter/migrator.rb
module ROM::CustomAdapter
  class Migrator < ROM::Migrator
    # ... 
    migration_template File.expand_path("../migration.erb", __FILE__)
    # ...
  end
end
```
```ruby
# spec/unit/rom-custom_adapter/migrator_spec.rb
describe ROM::CustomAdapter::Migrator do
  let(:migrator) { described_class.new }

  describe "#template" do
    subject { migrator.template "Bar::Foo" }

    it "returns the proper template" do
      expect(subject).to eql <<-TEMPLATE.gsub(/\s+\|/, "")
        |module Bar::Foo < ROM::CustomAdapter::Migration
        |  def up
        |  end
        |
        |  def down
        |  end
        |end
      TEMPLATE
    end
  end
end
```

#### Provide the Base Migration

The migration API includes 2 public instance methods: `#up` and `#down`. Base migration should define adapter-specific helpers for this methods.

You MUST use the current `#gateway` (link to the gateway instance) **as the only access point to the persistence!**

```ruby
# lib/rom-custom_adapter/migration.rb
module ROM::CustomAdapter
  class Migration < ROM::Migrator::Migration # notice the Migrator namespace!

    # Drops the table in a persistence
    #
    # @example
    #   class CreateFoo < ROM::Migration[:custom_adapter]
    #     # ...
    #
    #     def down
    #       drop_table :foo
    #     end
    #   end
    #
    # @param [#to_s] name
    #
    # @return [undefined]
    #
    def drop_table(name)
      # Define `send` method in a gateway and use it here:
      gateway.send "DROP TABLE #{name};"
    end
  end
end
```
```ruby
# spec/unit/rom-custom_adapter/migration_spec.rb
describe ROM::CustomAdapter::Migration do
  let(:migration) { described_class.new gateway }
  let(:gateway)   { double :gateway, send: nil }

  describe "#drop_table" do
    subject { migration.drop_table :foo }

    it "sends DROP TABLE command to gateway" do
      expect(gateway).to receive(:send).with "DROP TABLE foo;"
    end
  end
end
```

#### Add Rake Task

Now that you has a base class for migrations, you can define a rake task to scaffold one:

```ruby
# lib/rom-custom_adapter/tasks.rake
require "rom-custom_adapter"

namespace :rom do
  namespace :custom_adapter do
    describe "Creates a migration by name with optional path to folder:" \
             "\nrom:custom_adapter:migration[NAME, custom/path]" \
             "\nrom:custom_adapter:migration[NAME]"
    task :migration, [:name, :path] do |t, *args|
      ROM::CustomAdapter::Migrator.generate(*args)
    end
  end
end
```

### When using Custom Adapter

When all the stuff before is done, you can use migrator in the application.

To scaffold the migration load the task in Rakefile:

```ruby
# Rakefile
load "rom-custom_adapter/tasks.rake"
```

then run the task from command line:

```
$ rake rom-custom_adapter:migration[create_foo]
```

To run migrations you need to connect to persistence datastore:

```ruby
require "rom-custom_adapter"

# Set rom environment
env = ROM::Environment.new
env.use :auto_registration
setup = env.setup :custom_adapter #, whatever additional settings
# ...
setup.finalize
rom = setup.env

# Migrate the datastore using the environment's gateway
rom.migrator.migrate  # runs all migrations
rom.migrator.rollback # rolls all migrations back
```

Methods `#migrate` and `#rollback` takes two options:

- the target version to migrate/rollback to (all migrations by default)
- the list of custom migration folders (`"db/migrate"` by default)

```ruby
# Migrations will be taken from folders
rom.migrate paths: "db/migrate", "spec/dummy/db/migrate"

# Migrations will be applied from the current version to the target
rom.migrate target: "20170101234319"

# Or rolled back from the current version to the target one
rom.rollback target: "20170101234319"
```

Installation
------------

Add this line to your application's Gemfile:

```ruby
# Gemfile
gem "rom-migrator"
```

Then execute:

```
bundle
```

Or add it manually:

```
gem install rom-migrator
```

Design
------

See the [class diagram at yUML][uml].

Compatibility
-------------

Tested under rubies [compatible to MRI 1.9+][rubies].

Uses [RSpec][rspec] 3.0+ for testing and [hexx-suit][hexx-suit] for dev/test tools collection.

Contributing
------------

* [Fork the project][github]
* Create your feature branch (`git checkout -b my-new-feature`)
* Add tests for it
* Run `rubocop` and `inch --pedantic` to ensure the style and inline docs are ok
* Run `rake mutant` or `rake exhort` to ensure 100% [mutant-proof][mutant] coverage
* Commit your changes (`git commit -am '[UPDATE] Add some feature'`)
* Push to the branch (`git push origin my-new-feature`)
* Create a new Pull Request

License
-------

See the [MIT LICENSE](LICENSE).

[codeclimate]: https://codeclimate.com/github/rom-rb/rom-migrator
[coveralls]: https://coveralls.io/r/rom-rb/rom-migrator
[gem]: https://rubygems.org/gems/rom-migrator
[gemnasium]: https://gemnasium.com/rom-rb/rom-migrator
[github]: https://github.com/rom-rb/rom
[guide]: http://rom-rb.org/guides/adapters/how-to/
[hexx-suit]: https://github.com/nepalez/hexx-suit
[inch]: https://inch-ci.org/github/rom-rb/rom-migrator
[license]: LICENSE
[mutant]: https://github.com/mbj/mutant
[rom]: http://rom-rb.org
[rspec]: http://rspec.org
[rubies]: .travis.yml
[travis]: https://travis-ci.org/rom-rb/rom-migrator
[uml]: http://yuml.me/853c702f
