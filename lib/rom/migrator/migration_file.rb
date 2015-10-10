# encoding: utf-8

class ROM::Migrator

  # Describes the migration file
  #
  # Knows how to convert [#path] inside a [#root] folder
  # to [#klass] and [#number] of migration. Alternatively
  # converts [#klass] and [#number] to [#path] in a [#root].
  #
  # Eventually it instantiates the migration for a specific migrator and logger,
  # using [#to_migration] method.
  #
  # @example Instantiates the migration described in a file by [#path]
  #   MigrationFile.new(
  #     root: "/my_gem/db/migrate",
  #     path: "/my_gem/db/migrate/my_gem/20170101120342822_create_users.rb"
  #   ).to_migration
  #   # => <MyGem::CreateUsers @number="20170101120342822">
  #
  # @example Defines the path to store migration with [#klass] and [#number]
  #   MigrationFile.new(
  #     root:   "/my_gem/db/migrate",
  #     klass:  "MyGem/CreateRoles",
  #     number: "20170101120419238"
  #   ).path
  #   # => "/my_gem/db/migrate/my_gem/20170101120419238_create_roles.rb"
  #
  # @author nepalez <andrew.kozin@gmail.com>
  #
  class MigrationFile

    include ROM::Options, Errors, Immutability

    option :root,   reader: true, type: String, required: true
    option :klass,  reader: true
    option :number, reader: true
    option :path,   reader: true

    # @!method initialize(options)
    # Initializes the file description instance
    #
    # @option options [#to_s] :root   The full path to migrations root folder
    # @option options [#to_s] :path   The full path to migration file
    # @option options [#to_s] :klass  The class name of the migration
    # @option options [#to_s] :number The number of the migration
    #
    def initialize(options)
      super(options)
      path ? initialize_from_path : initialize_from_klass_and_number
      validate_file
    end

    # Loads the file and initializes the migration it describes
    #
    # @param [Hash] options
    # @option options [ROM::Migrator] migrator
    #   The migrator that provides access to persistence for migration
    # @option options [::Logger] logger
    #   The custom logger to report migration's result
    #
    # @return [ROM::Migrator::Migration]
    #
    def to_migration(options)
      require path
      constant.new options.merge(number: number)
    end

    private

    KLASS = Functions[:klass]
    PARTS = Functions[:path_to_parts]
    PATH  = Functions[:parts_to_path]

    def initialize_from_path
      @klass, @number = PARTS[relative_path]
    end

    def initialize_from_klass_and_number
      @path = File.join(root, PATH[klass, number])
    end

    def relative_path
      Pathname.new(path).relative_path_from(Pathname.new(root)).to_s
    end

    def validate_file
      return if valid_klass? && valid_number?
      fail MigrationNameError.new(path)
    end

    def valid_klass?
      klass && !klass.empty?
    end

    def valid_number?
      @number = @number.to_s
      !number.empty?
    end

    def constant
      KLASS[klass]
    end

  end # class MigrationFile

end # class ROM::Migrator
