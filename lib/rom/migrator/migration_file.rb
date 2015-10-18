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

    include ROM::Options, Errors, Immutability
    option :number,  reader: true, coercer: -> num { num.to_s }
    option :content, reader: true, default: "ROM::Migrator.migration"

    # Loads the migration file from disk
    #
    # @param [String] path
    #
    # @return [ROM::Migrator::MigrationFile]
    #
    def self.from_file(path)
      number = Pathname.new(path).basename(".rb").to_s[/^[^_]+/]
      fail NotFoundError.new(number) unless File.exist? path
      content = File.read(path)

      new(number: number, content: content)
    end

    # Checks whether the content describes a migration
    #
    # Used to skip files that are definitely not a migrations.
    # The check is preliminary: content evaluation still can raise an error.
    #
    # @return [Boolean]
    #
    def valid?
      return false if number.empty?
      !content[/ROM::([A-Z][A-z]*::)?Migrator(\.m|::M)igration/].nil?
    end

    # Loads the file and initializes the migration it describes
    #
    # @param [Hash] options
    #
    # @return [ROM::Migrator::Migration]
    #
    def to_migration(options)
      raise_error unless valid?
      migration_klass.new options.merge(number: number)
    end

    private

    def migration_klass
      klass = eval(@content)
    rescue StandardError, SyntaxError
      raise_error
    else
      raise_error unless subclass_of_migration?(klass)
      klass
    end

    def raise_error
      fail ContentError[number]
    end

    def subclass_of_migration?(object)
      object.ancestors.include? Migration rescue nil
    end

  end # class MigrationFile

end # class ROM::Migrator
