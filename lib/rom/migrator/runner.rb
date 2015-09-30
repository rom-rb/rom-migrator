# encoding: utf-8

class ROM::Migrator

  # Decorates the migrator with methods to apply / rollback migrations
  #
  # @api private
  #
  # @author nepalez <andrew.kozin@gmail.com>
  #
  class Runner

    include ROM::Options
    include Immutability
    include Enumerable

    option :folders, reader: true
    option :target, reader: true
    option :migrator, reader: true

    # @!attribute [r] files
    #
    # @return [ROM::Migrator::MigrationFiles]
    #   The collection of all migration files in selected folders, that can
    #   filter files by numbers.
    #   Its every item can either <load and> apply, or <load and> rollback
    #   a corresponding migration.
    #
    attr_reader :files

    # @!method initialize(options)
    # Initializes the collection
    #
    # @option options [String, Array<String>] :folders
    #   The list of folders where migrations should be found
    # @option options [String, nil] :target
    #   Optional target number to which the migrations should be applied,
    #   or rolled back
    # @option options [ROM::Migrator]
    #   The back reference to the migrator
    #
    def initialize(*)
      super
      @files = MigrationFiles.new(folders)
    end

    # Applies all migrations in the collection
    #
    # @return [undefined]
    #
    def apply
      files_to_apply
        .map { |file| file.build_migration(migrator) }
        .each(&:apply)
    end

    # Rolls back all migrations in the collection
    #
    # @return [undefined]
    #
    def rollback
      files_to_rollback
        .map { |file| file.build_migration(migrator) }
        .reverse_each(&:rollback)
    end

    private

    def files_to_apply
      files.after_numbers(registered).upto_number(target)
    end

    def files_to_rollback
      files.with_numbers(registered).after_numbers(target)
    end

    def registered
      migrator.registered
    end

  end # class Runner

end # class ROM::Migrator
