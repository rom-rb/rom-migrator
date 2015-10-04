# encoding: utf-8

class ROM::Migrator

  # Describes the migration file and loads it when necessary
  #
  # It defines connection between [#path], [#klass] and [#number] and
  # knows how to [#load] a corresponding migration.
  #
  # @example from path
  #   file = MigrationFile.new(
  #     folder: "/foo_bar",
  #     path: "/foo_bar/bar_baz/num123_baz_qux.rb"
  #   )
  #   file.path   # => "/foo_bar/bar_baz/num123_baz_qux.rb"
  #   file.number # => "num123"
  #   file.klass  # => "BarBaz::BazQux"
  #
  # Alternatively, file can be built with a number and a name, provided by user.
  #
  # @example from class name and number
  #   file = MigrationFile.new
  #     folder: "/foo_bar",
  #     klass:  "BarBaz::BazQux",
  #     number: "num"
  #   )
  #   file.path   # => "/foo_bar/bar_baz/num123_baz_qux.rb"
  #   file.number # => "num123"
  #   file.klass  # => "BarBaz::BazQux"
  #
  # @author nepalez <andrew.kozin@gmail.com>
  #
  class MigrationFile

    include ROM::Options
    include Errors

    option :folder, reader: true, type: String, required: true
    option :klass,  reader: true
    option :number, reader: true
    option :path,   reader: true

    # Pure functions
    PARTS = Functions[:path_to_parts]
    PATH  = Functions[:parts_to_path]
    CLASS = Functions[:constantize]

    # @!method initialize(options)
    # Initializes the file description instance
    #
    # @option options [#to_s] :folder The full path to the migrations folder
    # @option options [#to_s] :klass  The class name of the migration
    # @option options [#to_s] :number The number of the migration
    # @option options [#to_s] :path   The full path to migration
    #
    def initialize(*)
      super
      path ? initialize_from_path : initialize_from_klass_and_number
      fail MigrationNameError.new(path) unless valid_klass? && valid_number?
    end

    # Loads the file and builds the corresponding migration
    #
    # @param [ROM::Migrator] migrator
    #
    # @return [ROM::Migrator::Migration]
    #
    def build_migration(migrator)
      require path
      CLASS[klass].new(migrator: migrator, number: number)
    end

    private

    def initialize_from_path
      @klass, @number = PARTS[relative_path]
    end

    def initialize_from_klass_and_number
      @path = File.join(folder, PATH[klass, number])
    end

    def relative_path
      Pathname.new(path).relative_path_from(Pathname.new(folder)).to_s
    end

    def valid_klass?
      klass && !klass.empty?
    end

    def valid_number?
      number && !number.empty?
    end

  end # class MigrationFile

end # class ROM::Migrator
