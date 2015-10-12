# encoding: utf-8

class ROM::Migrator

  require_relative "migration_file"

  # Immutable collection of objects, describing migration files.
  #
  # Class factory method [.from] builds the collection of files from an array
  # of paths to folders, containing migrations.
  #
  # Every item (file) in a collection has its <migration> +number+.
  # The collection knows how to filter files by their numbers,
  # allowing to select migrations to be applied / reversed.
  #
  # Instance method [#to_migrations] converts the collection of files into
  # the corresponding collection of instantiated migrations.
  #
  # @example Instantiates necessary migrations from given paths
  #   MigrationFiles
  #     .from(list_of_paths)            # Convert a list of paths
  #     .upto_number(target_number)     # with migrations before the target,
  #     .after_numbers(applied_numbers) # that hasn't been applied yet,
  #     .to_migrations(                 # into a collection of migrations
  #       migrator: some_migrator,      # to be applied by some migrator
  #       logger: custom_logger         # using custom logger.
  #     )
  #
  # @api private
  #
  class MigrationFiles

    include Enumerable, Errors, Immutability

    # Builds the collection of migration files from a list of paths
    #
    # @param [String, Array<String>, nil] paths
    #
    # @return [ROM::Migrator::MigrationFiles]
    #
    def self.from(*paths)
      files = paths.flatten.map do |root|
        dirs = Dir[File.join(root, "**/*.rb")]
        dirs.map { |path| MigrationFile.new(root: root, path: path) }
      end
      new files
    end

    # Initializes the collection with a list of migration files
    #
    # @param [Array<ROM::Migrator::MigrationFile>] files
    #
    def initialize(*files)
      @files = files.flatten
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
    # @param [String, Array<String>] numbers
    #
    # @return [ROM::Migrator::MigrationFiles]
    #
    # @raise [ROM::Migrator::Errors::NotFoundError]
    #   when migration with given number is absent
    #
    def with_numbers(*numbers)
      numbers = numbers.flatten.compact
      update { @files = numbers.map(&method(:ensure)) }
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
    def to_migrations(migrator)
      Migrations.new map { |file| file.to_migration(migrator) }
    end

    private

    # Either finds file by number, or fails
    def ensure(number)
      detect { |file| file.number.eql? number } ||
        fail(NotFoundError.new number)
    end

  end # class MigrationFiles

end # class ROM::Migrator
