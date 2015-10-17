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

- provide *adapter-specific* methods to [register applied migrations](#define-how-to-register-migrations)
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

### Define how to register migrations

You MUST define 4 adapter-specific operations, that allow migrator to register/unregister applied migration, and find their numbers.

Blocks are called in the context of the corresponding gateway:

```ruby
# Suppose the gateway responds to #send_query

# lib/rom-custom_adapter/migrator.rb
module ROM::CustomAdapter
  class Migrator < ROM::Migrator
    # ...

    prepare_registry do
      send_query "CREATE TABLE IF NOT EXISTS rom_custom_adapter_migrations;"
    end

    register do |number|
      send_query "INSERT number = '#{number}' INTO rom_custom_adapter_migrations;"
    end

    unregister do |number|
      send_query "DELETE FROM rom_custom_adapter_migrations WHERE number = '#{number}';"
    end

    registered do
      send_query("SELECT number FROM rom_custom_adapter_migrations;").map(&:number)
    end
  end
end
```

You aren't restricted by a gateway as a storage of migrations. The same API can be implemented using a file system or remote server.

For example you can create / remove a file with a corresponding number inside a special folder:

```ruby
module ROM::CustomAdapter
  class Migrator < ROM::Migrator
    REGISTRY = "db/migrate/applied_migrations"

    prepare_registry { FileUtils.mkdir_p REGISTRY }
    register         { |number| FileUtils.touch "#{ REGISTRY}/.#{ number}" }
    unregister       { |number| FileUtils.rm_f  "#{ REGISTRY}/.#{ number}" }
    registered       { Dir["#{ REGISTRY}/.*"].map { |fn| fn[/\.[^.]$/] } }
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

Reload `#default_counter` method, that defines the number of the migration being generated.

By default the number is a timestamp in `%Y%m%d%H%M%S%L` format (17 digits for the current UTC time in milliseconds).

Notice, that migrator will order migrations by *stringified* numbers in the *ascending* order. That's why stringified output of the method MUST be greater than its stringified argument. See inline comments below for the contract:

```ruby
# lib/rom-custom_adapter/migrator.rb
module ROM::CustomAdapter
  class Migrator < ROM::Migrator
    # ...
    default_counter { |last_number| last_number.to_i + 1 }
    # ...
  end
end
```

### Customize migration template

The default template is provided by the `rom-migrator` gem.

You can customize the template, for example, to add comments with available methods as shown below.

```
# lib/rom-custom_adapter/migration.txt
ROM::Migrator.migration do
  up do
    # create_table(:table_name).set(name: :text, age: :int).primary_key(:name)
  end

  down do
    # drop_table(:table_name)
  end
end
```

Let the migrator to know a path to the template:

```ruby
# lib/rom-custom_adapter/migrator.rb
module ROM::CustomAdapter
  class Migrator < ROM::Migrator
    # ... 
    default_template File.expand_path("../migration.txt", __FILE__)
    # ...
  end
end
```

Using Migrator in Application
-----------------------------

To use a migrator you have to set rom environment and prepare a +gateway+:

```ruby
require "rom-custom_adapter"

# Set rom environment
env = ROM::Environment.new
env.use :auto_registration
setup = env.setup :custom_adapter #, whatever additional settings
# ...
setup.finalize
rom = setup.env

# Use a gateway
gateway = rom.gateways[:default]
```

Then access the migrator via corresponding Gateway:

```ruby
migrator = gateway.migrator
```

By default the migrator will look for migrations in the [adapter-specific default path](#customize-default-path-to-migrations). You can change the path explicitly:

```ruby
migrator = gateway.migrator path: "db/migrate/custom_adapter"
```

You can also refer to a list of folders, containing migrations:

```ruby
migrator = gateway.migrator paths: ["db/migrate", "spec/dummy/db/migrate"]
```

The migrator publishes log messages to `$stdout`. To change this option you can set a custom logger (some kind of ruby `::Logger` klass):

```ruby
logger = ::Logger.new(::StringIO.new)
migrator = gateway.migrator logger: logger
```

You can customize a template for migrations and a counter as well:

```ruby
migrator = gateway.migrator template: "config/migration.txt", counter: proc { |_| Time.now.strftime "%Y%m%d%H%M%#{rand(1000..9999)}" }
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

By default migration number will be provided via counter. You can set the number explicitly:

```ruby
migrator.migration(number: "1") do
  # ...
end
```

### Running migrations

Use the `apply` and `reverse` methods to apply or reverse migrations:

```ruby
migrator.apply    # runs all migrations from the default folder
migrator.reverse  # reverses migrations back
```

Both methods take an option `:target` for a version to migrate persistence to.

```ruby
# All migrations, that hasn't been applied before, will be applied
migrator.apply

# Only those migrations, that hasn't been applied before,
# and whose numbers not greater when the target, will be applied
migrator.apply target: "20170101234319"

# All registered (applied) migrations, whose numbers not less when the target,
# will be reversed
migrator.reverse target: "20170101234319"
```

When reversing a migration you can also use `:allow_missing_files` option. In this case when migrator will try to reverse a number that is absent on disk, it will unregister the number and keep reversion further.

```ruby
migrator.reverse allow_missing_files: true
```

Otherwise it will raise an exception complaining it has no recipy how to roll back the migrations.

### Scaffolding a Migration

Use the `#generator` method to scaffold new migration. You MUST provide the name of the migration class:

```ruby
migrator.create_file
# => `db/migrate/{next_number}.rb
```

You can customize options: `:path`, `:number` and `:name` for migration, `:logger` and `:template`.

```ruby
migrator.create path: "db/migrate/custom", name: "create_users", number: "1"
# => `db/migrate/custom/1_create_users.rb
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
