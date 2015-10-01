[WIP] ROM::Migrator
===================

[![Gem Version](https://img.shields.io/gem/v/rom-migrator.svg?style=flat)][gem]
[![Build Status](https://img.shields.io/travis/rom-rb/rom-migrator/master.svg?style=flat)][travis]
[![Dependency Status](https://img.shields.io/gemnasium/rom-rb/rom-migrator.svg?style=flat)][gemnasium]
[![Code Climate](https://img.shields.io/codeclimate/github/rom-rb/rom-migrator.svg?style=flat)][codeclimate]
[![Coverage](https://img.shields.io/coveralls/rom-rb/rom-migrator.svg?style=flat)][coveralls]
[![Inline docs](http://inch-ci.org/github/rom-rb/rom-migrator.svg)][inch]

Base class for [ROM][rom] migrators.

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

Usage
-----

When creating custom ROM adapter, you should implement its own migrator inherited from `ROM::Migrator`:

- [load the gem](#load-the-gem)
- [provide the migrator](#provide-the-migrator)

and customize it as following:

- provide *adapter-specific* methods to [register applied migrations](#implement-methods-to-register-migrations)
- provide *adapter-specific* methods to [make changes to persistence](#implement-methods-to-make-changes-to-persistence) via ROM gateway

You can also redefine some default settings, namely:

- [default path to migrations](#customize-default-path-to-migrations) (`db/migrate`)
- [path to template for migrations](#customize-migration-template)
- [migration number counter](#customize-migration-number-counter)

### Load the Gem

Install and require the gem. It is not loaded by default because there is a bunch of adapters that doesn't need mingrators.

```ruby
# lib/rom-custom_adapter.rb
require "rom"
require "rom-migrator"
```

### Provide the Migrator

Subclass the migrator from `ROM::Migrator`:

```ruby
# lib/rom-custom_adapter/migrator.rb
module ROM::CustomAdapter
  class Migrator < ROM::Migrator
  end
end
```

### Implement methods to register migrations

You MUST define adapter-specific methods, that allow migrator to register/unregister applied migration in a persistence, and find their numbers.

*In case the adapter's gateway supports `send_query` method*, the definitions can be like the following:

```ruby
# lib/rom-custom_adapter/migrator.rb
module ROM::CustomAdapter
  class Migrator < ROM::Migrator
    # ...

    # Prepares the table to store applied migrations in a persistence if it is absent.
    #
    # @return [undefined]
    #
    def prepare_registry
      gateway.send_query "CREATE TABLE IF NOT EXISTS rom_custom_adapter_migrations;"
    end

    # Registers the number of migration being applied
    #
    # @param [String] number
    #
    # @return [undefined]
    #
    def register(number)
      gateway.send_query "INSERT number = '#{number}' INTO rom_custom_adapter_migrations;"
    end

    # Unregisters the number of migration being rolled back
    #
    # @param [String] number
    #
    # @return [undefined]
    #
    def unregister(number)
      gateway.send_query "DELETE FROM rom_custom_adapter_migrations WHERE number = '#{number}';"
    end

    # Returns the array of registered numbers of applied migrations
    #
    # @return [Array<String>]
    #
    def registered
      gateway.send_query("SELECT number FROM rom_custom_adapter_migrations;").map(&:number)
    end
  end
end
```

### Implement methods to make changes to persistence

The migration's `#up` and `#down` methods make changes to datastore. In ROM every **gateway** defines its own low-level API to the persistence.

You MUST use the current `#gateway` (link to the gateway instance) **as the only access point to the persistence!**
You should provide methods like `create`, `delete`, `update` etc., that will be accessible to migrations.

```ruby
# lib/rom-custom_adapter/migrator.rb
module ROM::CustomAdapter
  class Migrator < ROM::Migrator
    # ...
    def create_table(name)
      generator.send_query "CREATE TABLE #{name};"
    end

    def drop_table(name)
      generator.send_query "DROP TABLE #{name};"
    end
  end
end
```

### Customize default path to migrations

By default migrations are expected to be found in `db/migrate`.

```ruby
# lib/rom-custom_adapter/migrator.rb
module ROM::CustomAdapter
  class Migrator < ROM::Migrator
    # ...
    default_path "db/migrate/custom_adapter"
    # ...
  end
end
```

### Customize migration number counter

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

### Customize migration template

The default template is provided by the `rom-migrator` gem.

To add custom template you have to:

- create the template
- set the path to custom template in a migrator 

The tempate should be ERB file where `@klass` contains the name of the migration.

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
```
# lib/rom-custom_adapter/migration.erb
class <%= @klass %> < ROM::Migrator::Migration
  def up
  end

  def down
  end
end
```

Notice the `Migration` namespace for base migration class above.

Using migrator in Application
-----------------------------

To use a migrator you have to prepare ROM environment first:

```ruby
require "rom-custom_adapter"

# Set rom environment
env = ROM::Environment.new
env.use :auto_registration
setup = env.setup :custom_adapter #, whatever additional settings
# ...
setup.finalize
rom = setup.env

# Access the migrator via corresponding Gateway:
migrator = rom.gateways[:default].migrator
```

### Running migrations

Use the `apply` and `rollback` methods to apply or roll back migrations:

```ruby
migrator.apply    # runs all migrations from the default folder
migrator.rollback # rolls all migrations back
```

The methods take two options:

- the **target** version to migrate/rollback
- the list of custom migration **folders** (`db/migrate` by default)

```ruby
# Migrations will be taken from folders
migrator.apply folders: ["db/migrate", "spec/dummy/db/migrate"]

# Migrations will be applied from the current version to the target
migrator.apply target: "20170101234319"

# Or rolled back from the current version to the target one
migrator.rollback target: "20170101234319"
```

### Scaffolding a Migration

Use the `#generator` method to scaffold new migration. You have to provide the name of the migration class:

```ruby
migrator.generate klass: "Users::CreateUser"
# => `db/migrate/users/1_create_user.rb
```

The generator will check the content of the <default> folder to find out the number of the last migration, and then use `#next_migration_number`.

You're expected to give it a list of all folders, that contain migrations. Otherwise the scaffolder can provide wrong migration number.

The order of folders is sufficient because new migration will be placed to the first one (the others are only used to check existing migrations):

```ruby
migrator.generate klass: "Users::CreateUser", folders: ["db/migrate", "spec/dummy/db/migrate"]
# => "/db/migrate/users/1_create_user.rb"

migrator.generate klass: "Users::CreateUser", folders: ["spec/dummy/db/migrate", "db/migrate"]
# => "/spec/dummy/db/migrate/users/1_create_user.rb"
```

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
