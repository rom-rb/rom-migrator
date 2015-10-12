# encoding: utf-8

class ROM::Migrator

  # Migrates the persistence to optional target version
  #
  # @api private
  #
  # @author nepalez <andrew.kozin@gmail.com>
  #
  class Runner

    include ROM::Options
    include Enumerable

    option :target, reader: true

    # Instantiates and applies the runner at once
    #
    # @param (see #initialize)
    # @option (see #initialize)
    #
    # @return [undefined]
    #
    def self.apply(migrator, options)
      new(migrator, options).apply
    end

    # Instantiates the runner and reverses migrations at once
    #
    # @param (see #initialize)
    # @option (see #initialize)
    #
    # @return [undefined]
    #
    def self.reverse(migrator, options)
      new(migrator, options).reverse
    end

    # @!attribute [r] migrator
    #
    # @return [ROM::Migrator] The decorated migrator
    #
    attr_reader :migrator

    # Initializes the runner object
    #
    # @param [ROM::Migrator] migrator
    #   The migrator, that provides access to persistence
    # @param [Hash] options
    # @option options [String, nil] :target The target version to migrate to
    #
    def initialize(migrator, options)
      super options
      @migrator = migrator
    end

    # Applies all migrations in the collection
    #
    # @return [undefined]
    #
    def apply
      files
        .after_numbers(registered)
        .upto_number(target)
        .to_migrations(migrator)
        .apply
    end

    # Reverses all migrations in the collection
    #
    # @return [undefined]
    #
    def reverse
      files
        .with_numbers(registered)
        .after_numbers(target)
        .to_migrations(migrator)
        .reverse
    end

    private

    def files
      MigrationFiles.from(folders)
    end

    def folders
      migrator.folders
    end

    def registered
      migrator.registered
    end

  end # class Runner

end # class ROM::Migrator
