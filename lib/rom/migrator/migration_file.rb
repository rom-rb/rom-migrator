# encoding: utf-8

class ROM::Migrator

  # A simple immutable structure describing numbered migration file
  #
  # Responcible for exposing migration's number and instantiating
  # the migration when necessary.
  #
  # @example Instantiates the migration described in a file by [#path]
  #   file = MigrationFile.new(
  #     path: "/db/migrate/20170101120342822_create_users.rb"
  #   )
  #   file.number # => "20170101120342822"
  #
  #   file.to_migration(migrator)
  #   # => <ROM::Migrator::Migration @number="20170101120342822">
  #
  # @author nepalez <andrew.kozin@gmail.com>
  #
  class MigrationFile

    include Errors, Immutability

    # @!attribute [r] number
    #
    # @return [String] The version number of the migration
    #
    attr_reader :number

    # Initializes the object with absolute path to migration
    #
    # @param [#to_s] path The full path to migration file
    #
    def initialize(path)
      @path    = path.to_s
      @content = content
      @number  = set_number
    end

    # Checks whether the file is a valid migration
    #
    # @return [Boolean]
    #
    def valid?
      (number && check_content) ? true : false
    end

    # Loads the file and initializes the migration it describes
    #
    # @param [Hash] options
    #
    # @return [ROM::Migrator::Migration]
    #
    def to_migration(options)
      klass.new options.merge(number: number)
    end

    private

    def content
      File.read(@path)
    rescue
      ""
    end

    def klass
      result = eval(@content)
    rescue => error
      raise_error(error)
    else
      raise_error(result) unless subclass_of_migration?(result)
      result
    end

    def raise_error(result)
      fail ContentError[@path, result]
    end

    def set_number
      Pathname.new(@path).basename(".rb").to_s[/^[^_]+/]
    end

    def check_content
      @content[/ROM::Migrator\.migration\s+(do|\{)/]
    end

    def subclass_of_migration?(object)
      return unless object.respond_to? :superclass
      Migration.equal? object.superclass
    end

  end # class MigrationFile

end # class ROM::Migrator
