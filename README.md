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

You MUST define adapter-specific methods, that allow migrator to register/unregister applied migration, and find their numbers.

Use the `#gateway` to access persistence (all methods not defined by a migrator are forwared to the gateway).

```ruby
# Supposet the gateway responds to #send_query

# lib/rom-custom_adapter/migrator.rb
module ROM::CustomAdapter
  class Migrator < ROM::Migrator
    # ...

    # Prepares the table to store applied migrations in a persistence if it is absent.
    #
    # @return [undefined]
    #
    def prepare_registry
      # sends to #gateway explicitly
      gateway.send_query "CREATE TABLE IF NOT EXISTS rom_custom_adapter_migrations;"
    end

    # Registers the number of migration being applied
    #
    # @param [String] number
    #
    # @return [undefined]
    #
    def register(number)
      # implicitly forwards #send_query to #gateway
      send_query "INSERT number = '#{number}' INTO rom_custom_adapter_migrations;"
    end

    # Unregisters the number of migration being reversed
    #
    # @param [String] number
    #
    # @return [undefined]
    #
    def unregister(number)
      send_query "DELETE FROM rom_custom_adapter_migrations WHERE number = '#{number}';"
    end

    # Returns the array of registered numbers of applied migrations
    #
    # @return [Array<String>]
    #
    def registered
      send_query("SELECT number FROM rom_custom_adapter_migrations;").map(&:number)
    end
  end
end
```

You aren't restricted by a gateway as a storage of migrations. The same API can be implemented using a file system or remote server.

### Implement methods to make changes to persistence

Provide methods like `create`, `delete`, `update` etc., that will be accessible to migrations, using the `#gateway` **as the only access point to persistence!**:

```ruby
# lib/rom-custom_adapter/migrator.rb
module ROM::CustomAdapter
  class Migrator < ROM::Migrator
    # ...
    def create_table(name)
      send_query "CREATE TABLE #{name};"
    end

    def drop_table(name)
      send_query "DROP TABLE #{name};"
    end
  end
end
```

### Customize default path to migrations

By default migrations are expected to be found in `db/migrate`. You can redefine this settings for custom adapter:

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

Reload `#next_migration_number` method, that defines the number of the migration being generated.

By default the number is a timestamp in `%Y%m%d%H%M%S%L` format (17 digits for the current UTC time in milliseconds).

Notice, that migrator will order migrations by *stringified* numbers in the *ascending* order. That's why stringified output of the method MUST be greater than its stringified argument. See inline comments below for the contract:

```ruby
# lib/rom-custom_adapter/migrator.rb
module ROM::CustomAdapter
  class Migrator < ROM::Migrator
    # ...

    # Returns the sequential number for the next migration
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

You can customize the template, for example, to add comments with available methods as shown below. It should be ERB file where `@klass` variable provides the name for the migration class.

```
# lib/rom-custom_adapter/migration.erb
class <%= @klass %> < ROM::Migrator::Migration
  up do
    # create_table(:table_name).set(name: :text, age: :int).primary_key(:name)
  end

  down do
    # drop_table(:table_name)
  end
end
```

Notice the `Migrator` namespace for the base `Migration` above.

Let the migrator to know a path to the template:

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
```

Then access the migrator via corresponding Gateway:

```ruby
migrator = rom.gateways[:default].migrator
```

### Building inline migration

You can build and apply the migration inline:

```ruby
migration = migrator.migration do
  up do
    create_table :foo
  end

  down do
    drop_table :foo
  end
end

migration.apply   # changes the persistence
migration.reverse # reverses the changes
```

**Be aware** that such a migration has no number. It won't be registered (added to the stored list of applied migrations) and cannot be authomatically reversed after `migration` object is utilized by GC. That's why this method of migration is useful for dev/test only. **Don't use it in production!**

You can also redefine logger used by the migration. This can be useful in specs when you don't need info messages in stdout:

```ruby
logger = ::Logger.new(StringIO.new)

migration = migrator.migration logger: logger do
  # whatever
end
```

### Running migrations

Use the `apply` and `reverse` methods to apply or reverse migrations:

```ruby
migrator.apply    # runs all migrations from the default folder
migrator.reverse  # reverses migrations back
```

Both methods take three additional options:

- a list of custom migrations **folders** (uses either `db/migrate`, or [another custom folder](#customize-default-path-to-migrations) by default)
- a **target** version to migrate/reverse (applies / reverses all versions by default)
- a custom **logger** (prints to `$stdout` by default)

```ruby
# All migrations from given folders will be applied
migrator.apply folders: ["db/migrate", "spec/dummy/db/migrate"]

# Migrations from `db/migrate` will be applied from the current version to the target
migrator.apply target: "20170101234319"

# Or reversed from the current version to the target one
migrator.reverse target: "20170101234319"
```

By default the results are printed to `$stdio`. You can change this by setting a custom logger (an instance of `::Logger`):

```ruby
migrator.apply logger: ::Logger.new(StringIO.new)
```

Notice, that if you use a list of folders, then migrations will be applied/reversed in order of their numbers regardless of location.

Suppose `db/migrate` contains migrations number 1 and 3, and `spec/dummy/db/migrate` contains numbers 2 and 4.

```ruby
migrator.apply folders: ["db/migrate", "spec/dummy/db/migrate"]
# will apply migrations in the ascending order: [1, 2, 3, 4]
```

Call a migrator several times if you need to apply migrations from various folders independently.

```ruby
migrator.apply folders: ["db/migrate"]
# will apply migrations: [1, 3]
migrator.apply folders: ["spec/dummy/db/migrate"]
# will apply migration [4] (2 is skipped because at the moment of applying the current version were already 3)
```

### Scaffolding a Migration

Use the `#generator` method to scaffold new migration. You MUST provide the name of the migration class. Migration number CAN be provided as well:

```ruby
migrator.generate klass: "Users::CreateUser", number: "1"
# => `db/migrate/users/1_create_user.rb
```

The result will be stored in the default folder.

When the number is skipped, the generator will check the content of the <default> folder to find out the number of the last migration, and apply `#next_migration_number` method to count the number for the migration being created.

```ruby
# Suppose the maximum number of migrations in `db/migrate` is "3"

migrator.generate klass: "users/create_user"
# => `db/migrate/users/4_create_user.rb
```

You can customize a list of all folders, that contain migrations. Their order is sufficient because new migration will be placed to the first one, while the others are only used to check existing migrations:

```ruby
# Suppose the maximum number of migrations in `db/migrate` and `spec/dummy/db/migrate` is "4"

migrator.generate klass: "users/create_user", folders: ["db/migrate", "spec/dummy/db/migrate"]
# => "/db/migrate/users/5_create_user.rb"

migrator.generate klass: "Users::CreateRole", folders: ["spec/dummy/db/migrate", "db/migrate"]
# => "/spec/dummy/db/migrate/users/6_create_role.rb"
```

Notice, that a migrator provides nested folders inside the target directory following the namespace of the migration.

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
