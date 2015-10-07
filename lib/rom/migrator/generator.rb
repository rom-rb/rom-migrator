# encoding: utf-8

require "erb"

class ROM::Migrator

  require_relative "generator/binding"

  # Scaffolds next migration from name and paths to existing migrations
  #
  # Uses the migrator to define the next migration number and
  # adapter-specific template
  #
  # @api private
  #
  # @author nepalez <andrew.kozin@gmail.com>
  #
  class Generator

    include ROM::Options

    option :folders,  reader: true
    option :klass,    reader: true, type: String, required: true
    option :migrator, reader: true
    option :number,   reader: true

    # Generates new migration it the corresponding folder using default template
    #
    # @param [Hash] options
    # @option (see #initialize)
    #
    # @return (see #call)
    #
    def self.call(options)
      new(options).call
    end

    # @!method initialize(options)
    # Initializes the generator
    #
    # @option (see ROM::Migrator#generate)
    #
    def initialize(_)
      super
      @klass  = Functions.fetch(:up)[@klass]
      @number = (number || migrator.next_migration_number(last_number)).to_s
    end

    # Generates new migration it the corresponding folder using default template
    #
    # @return [self] itself
    #
    def call
      prepare_folder
      File.new(file.path, "w").write(content)
    end

    private

    def prepare_folder
      FileUtils.mkdir_p Pathname.new(file.path).dirname
    end

    def file
      MigrationFile.new folder: folders.first, klass: klass, number: number
    end

    def last_number
      last_migration = MigrationFiles.new(folders).to_a.last
      last_migration.number if last_migration
    end

    def content
      ERB.new(template).result(view_binding)
    end

    def template
      File.read(migrator.template)
    end

    def view_binding
      Binding[klass]
    end

  end # class Generator

end # class ROM::Migrator
