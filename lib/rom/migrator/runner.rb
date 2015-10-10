# encoding: utf-8

class ROM::Migrator

  # Decorates the migrator with methods to apply / reverse migrations
  #
  # @api private
  #
  # @author nepalez <andrew.kozin@gmail.com>
  #
  class Runner

    include ROM::Options
    include Enumerable

    option :folders,  reader: true
    option :migrator, reader: true
    option :target,   reader: true
    option :logger,   reader: true

    # Instantiates and applies the runner at once
    #
    # @param [Hash] options
    # @option (see #initialize)
    #
    # @return (see #apply)
    #
    def self.apply(options)
      new(options).apply
    end

    # Instantiates the runner and reverses migrations at once
    #
    # @param [Hash] options
    # @option (see #initialize)
    #
    # @return (see #reverse)
    #
    def self.reverse(options)
      new(options).reverse
    end

    # Applies all migrations in the collection
    #
    # @param [::Logger] logger
    #
    # @return [undefined]
    #
    def apply
      MigrationFiles
        .from(folders)
        .after_numbers(registered)
        .upto_number(target)
        .to_migrations(migrator: migrator, logger: logger)
        .apply
    end

    # Reverses all migrations in the collection
    #
    # @param [::Logger] logger
    #
    # @return [undefined]
    #
    def reverse
      MigrationFiles
        .from(folders)
        .with_numbers(registered)
        .after_numbers(target)
        .to_migrations(migrator: migrator, logger: logger)
        .reverse
    end

    private

    def registered
      migrator.registered
    end

  end # class Runner

end # class ROM::Migrator
