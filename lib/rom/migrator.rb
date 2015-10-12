# encoding: utf-8

require "immutability"
require "logger"
require "rom"

module ROM

  require_relative "migrator/functions"       # pure functions
  require_relative "migrator/errors"          # gem-specific errors

  require_relative "migrator/logger"          # default logger for migration
  require_relative "migrator/migration"       # changes the persistence
  require_relative "migrator/migrations"      # defines the order of migrations
  require_relative "migrator/migration_file"  # file description
  require_relative "migrator/migration_files" # filters files by their numbers

  require_relative "migrator/runner"          # applies / reverses migrations
  require_relative "migrator/generator"       # scaffolds migrations

  # The abstract base class for ROM migrators
  #
  # The migrator stores all adapter-specific settings
  # and defines APIwith 3 instance methods to:
  # - [#apply] migrations
  # - [#reverse] migrations
  # - [#generate] the next migration
  #
  # @example
  #   class ROM::Custom::Migrator < ROM::Migrator
  #     # default path to migrations folder
  #     default_path "db/migrate"
  #
  #     # path to adapter-specific template for scaffolding a migration
  #     template File.expand_path("../template.erb", __FILE__)
  #
  #     private
  #
  #     # counts number for the next migration
  #     def next_migration_number(last_number)
  #       last_number.to_i + 1
  #     end
  #
  #     # returns numbers of applied migrations
  #     def registered
  #       call "SELECT number FROM migrations;"
  #     end
  #
  #     # registers new applied migration
  #     def register(number)
  #       call "INSERT number '#{number}' INTO migrations;"
  #     end
  #
  #     # unregisters a migration being reversed
  #     def unregister(number)
  #       call "DELETE FROM migrations WHERE number='#{number}';"
  #     end
  #
  #     # other function to be accessible from migration's +#up+ and +#down+
  #     def where(options)
  #       gateway.where(options)
  #     end
  #   end
  #
  #   migrator = ROM::Custom::Migrator.new(
  #     gateway, # some gateway providing access to persistence
  #     folders: ["db/migrate", "db/custom"] # where migrations live
  #   )
  #
  # @author nepalez <andrew.kozin@gmail.com>
  #
  # @abstract
  #
  class Migrator

    # Gets or sets the adapter-specific default path to migrations
    #
    # @param [String, nil] value
    #
    # @return [String]
    #
    def self.default_path(value = nil)
      @default_path = value if value
      @default_path || "db/migrate"
    end

    # Gets or sets path to adapter-specific template for migrations
    #
    # @param [String] value
    #
    # @return [String]
    #
    def self.template(value = nil)
      @template = value if value
      @template || File.expand_path("rom/migrator/generator/template.erb")
    end

    # @!attribute [r] gateway
    #
    # @return [ROM::Gateway] the gateway to persistence
    #
    attr_reader :gateway

    # @!attribute [r] folders
    #
    # @return [String] the list of folders containing migrations
    #
    attr_reader :folders

    # @!attribute [r] logger
    #
    # @return [::Logger] the logger used to log results of applying migrations
    #
    attr_reader :logger

    # Initializes the migrator with reference to the gateway and list of
    # folders containing migrations.
    #
    # @param [ROM::Gateway] gateway
    # @option options [String, Array<String>] :folders
    #   The list of folders with migrations.
    #   Uses [.default_path] by default.
    # @option options [::Logger] :logger
    #   The custom logger to be used instead of default (that logs to +$stdout+)
    #
    def initialize(gateway, options = {})
      @gateway = gateway
      @folders = Array(options[:folders] || self.class.default_path)
      @logger  = options[:logger] || Logger.new

      prepare_registry # MUST be defined by adapter
    end

    # Path to migration's template
    #
    # @return [String]
    #
    def template
      self.class.template
    end

    # @!method next_migration_number(last_number)
    # Returns the number for the next migration.
    #
    # By default it provides the current timestamp in milliseconds (17 digits).
    # It can be reloaded by adapter-specific counter.
    #
    # @param [String] last_number The number of the last existing migration
    #
    # @return [#to_s]
    #
    def next_migration_number(_)
      Time.now.strftime "%Y%m%d%H%M%S%L"
    end

    # Defines and instantiates unnamed migration to be applied/reversed
    #
    # @param [Proc] block The migration definition (via +up+ and +down+ methods)
    #
    # @return [ROM::Migrator::Migration]
    #
    def migration(&block)
      Class.new(Migration, &block).new(self)
    end

    # Applies migrations
    #
    # @param  (see ROM::Migrator::Runner.apply)
    # @option (see ROM::Migrator::Runner.apply)
    #
    # @return [self] itself
    #
    def apply(options = {})
      run :apply, options
    end

    # Reverses migrations
    #
    # @param  (see ROM::Migrator::Runner.reverse)
    # @option (see ROM::Migrator::Runner.reverse)
    #
    # @return [self] itself
    #
    def reverse(options = {})
      run :reverse, options
    end

    # Generates the migration
    #
    # @example Generates migation
    #   migrator.generate(
    #     path:   "spec/dummy/db/migrate",
    #     klass:  "Users::Create",
    #     number: "1"
    #   )
    #   # => "spec/dummy/db/migrate/users/1_create.rb"
    #
    # @example Uses the first of migration folders by default
    #   migrator = gateway.migrator folders: ["db/migrate", "spec/dummy/db"]
    #   migrator.generate(
    #     klass:  "Users::Create",
    #     number: "1"
    #   )
    #   # => "db/migrate/users/1_create.rb"
    #
    # @example Provides the number using [#next_migration_number]
    #   migrator.generate(
    #     path:   "db/migrate",
    #     klass:  "Users::Create"
    #   )
    #   # => "db/migrate/users/20151012134401892_create.rb"
    #
    # @param [Hash] options
    # @option (see ROM::Migrator::Generator.call)
    #
    # @return (see ROM::Migrator::Generator.call)
    #
    def generate(options)
      Generator.call self, { path: folders.first }.merge(options)
    end

    private

    def run(command, options)
      Runner.public_send command, self, options
      self
    end

    def method_missing(*args)
      gateway.public_send(*args)
    end

    def respond_to_missing?(name, *)
      gateway.respond_to? name
    end

  end # class Migrator

end # module ROM
