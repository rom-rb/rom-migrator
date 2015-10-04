# encoding: utf-8

class ROM::Migrator

  require_relative "migration_file"

  # Immutable collection of migration files.
  #
  # It converts a *collection of folders*
  # into *collection of objects*, describing migration files in that folders.
  # Its every item defines +klass+, +number+ and +path+ to some migration.
  #
  # The collection is enumerable with method [#each] iterating via
  # file objects ordered by numbers in the ascending order.
  #
  # Use the following methods to filter the collection by migration numbers:
  # - [#with_numbers]
  # - [#after_numbers]
  # - [#upto_number]
  #
  # @example
  #   files = MigrationFiles.new(
  #     "/my_gem/db/migrate",
  #     "/my_gem/spec/dummy/db/migrate"
  #   )
  #
  #   files.map { |f| [f.number, f.klass, f.path] }
  #   # => [
  #   #      ["1", "Foo::Bar", "/my_gem/spec/dummy/db/migrate/foo/1_bar.rb"]
  #   #      ["2", "BazQux",   "/my_gem/db/migrate/2_baz_qux.rb"]
  #   #    ]
  #
  # @api private
  #
  class MigrationFiles

    include Enumerable
    include Errors

    # Pure functions
    CLEAN = Functions[:clean_array]

    # @!attribute [r] folders
    #
    # @return [Array<String>] The list of folders with migration files
    #
    attr_reader :folders

    # Initializes the collection from the list of selected folders
    #
    # @param [String, Array<String>, nil] folders
    #
    def initialize(*folders)
      @folders = CLEAN[folders]
      @files   = @folders.flat_map(&method(:build)).sort_by(&:number)
    end

    # Iterates through migration files
    #
    # @return [Enumerator]
    #
    # @yieldparam [ROM::Migrator::MigrationFile] file
    #
    def each
      block_given? ? @files.each { |file| yield(file) } : to_enum
    end

    # Builds new collection containing ALL files with given numbers.
    #
    # Allows to select migrations to be rolled back using registered numbers.
    #
    # @param [String, Array<String>] numbers
    #
    # @return [ROM::Migrator::MigrationFiles]
    #
    # @raise [ROM::Migrator::Errors::NotFoundError]
    #   when migration file with given number is absent
    #
    def with_numbers(*numbers)
      update { @files = CLEAN[numbers].map(&method(:find)) }
    end

    # Builds new collection with only those files, whose numbers are greater
    # than given one(s).
    #
    # Allows to select migrations to be applied using registered numbers.
    #
    # @param [String, Array<String>] numbers
    #
    # @return [ROM::Migrator::MigrationFiles]
    #
    def after_numbers(*numbers)
      list = CLEAN[numbers]
      return self if list.empty?
      update { @files = select { |file| file.number > list.last } }
    end

    # Builds new collection with those files whose numbers are less or equal
    # than given one.
    #
    # Allows to select migrations to be applied when target version is set.
    #
    # @param [String] number
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
      any? ? to_a.last.number : ""
    end

    private

    def build(dir)
      paths = Dir[File.join(dir, "**/*.rb")]
      paths.map { |path| MigrationFile.new(folder: dir, path: path) }
    end

    def find(number)
      result = detect { |file| number.eql? file.number }
      result || fail(NotFoundError.new(number, folders))
    end

    def update(&block)
      dup.tap { |instance| instance.instance_eval(&block) }
    end

  end # class MigrationFiles

end # class ROM::Migrator
