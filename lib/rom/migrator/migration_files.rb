# encoding: utf-8

class ROM::Migrator

  # Immutable collection of objects, describing migration files.
  #
  # Every item (file) in a collection has its <migration> +number+.
  # The collection knows how to filter files by their numbers,
  # allowing to select migrations to be applied / reversed.
  #
  # @api private
  #
  class MigrationFiles

    include ROM::Options, Enumerable, Errors, Immutability

    # Builds the collection of valid migration files from a list of paths
    # to folders containing migrations
    #
    # @param [Array<String>] paths
    # @param [Hash] options
    # @option options (see #initialize)
    #
    # @return [ROM::Migrator::MigrationFiles]
    #
    def self.from_folders(paths)
      new paths
        .flat_map { |folder| Dir[File.join(folder, "**/*.rb")] }
        .map(&MigrationFile.method(:from_file))
        .select(&:valid?)
    end

    # Initializes the collection with a list of migration files
    #
    # @param [Array<ROM::Migrator::MigrationFile>] files
    #
    def initialize(files)
      @files = files
    end

    # Iterates through files
    #
    # @return [Enumerator<ROM::Migrator::MigrationFile>]
    #
    # @yieldparam [ROM::Migrator::MigrationFile] file
    #
    def each
      block_given? ? @files.each { |file| yield(file) } : to_enum
    end

    # Returns a subset of files with given numbers
    #
    # @param [Array<String>] numbers
    # @param [Boolean] strict Whether missing files can be skipped
    #
    # @raise [ROM::Migrator::Errors::NotFoundError]
    #   when migration with given number is absent
    #
    def with_numbers(numbers, strict = true)
      update { @files = numbers.map { |num| search(num, strict) } }
    end

    # Returns a subset of files with numbers greater than given one(s)
    #
    # @param [String, Array<String>] numbers
    #
    # @return [ROM::Migrator::MigrationFiles]
    #
    def after_numbers(*numbers)
      numbers = numbers.flatten.compact
      return self if numbers.empty?
      update { @files = select { |file| file.number > numbers.last } }
    end

    # Returns a subset of files with numbers not greater than given one
    #
    # @param [String, nil] number
    #
    # @return [ROM::Migrator::MigrationFiles]
    #
    def upto_number(number = nil)
      return self unless number
      update { @files = select { |file| file.number <= number } }
    end

    # Returns the number of the last migration in the collection
    #
    # @return [String]
    #
    def last_number
      any? ? max_by(&:number).number : ""
    end

    # Returns the collection of migrations loaded from files and
    # instantiated with given migrator and logger
    #
    # @param (see ROM::Migrator::MigrationFile#to_migration)
    #
    # @return [ROM::Migrator::Migrations]
    #
    def to_migrations(options)
      Migrations.new map { |file| file.to_migration(options) }
    end

    private

    def search(number, strict)
      result = detect { |file| file.number.eql? number }
      return result if result
      strict ? fail(NotFoundError[number]) : MigrationFile.new(number: number)
    end

  end # class MigrationFiles

end # class ROM::Migrator
