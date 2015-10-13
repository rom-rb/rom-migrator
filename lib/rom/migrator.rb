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
  # - [#create_file] with the next migration
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
  #     paths: ["db/migrate", "db/custom"] # where migrations live
  #   )
  #
  # @author nepalez <andrew.kozin@gmail.com>
  #
  # @abstract
  #
  class Migrator

    NOTHING = Class.new.freeze
    DEFAULT_PATH = "db/migrate".freeze
    DEFAULT_TEMPLATE =
      File.expand_path("../migrator/generator/template.erb", __FILE__).freeze

    # Gets or sets the adapter-specific default path to migrations
    #
    # @param [String, nil] value
    #
    # @return [String]
    #
    def self.default_path(value = NOTHING)
      @default_path = value unless value.equal?(NOTHING)
      @default_path || DEFAULT_PATH
    end

    # Gets or sets path to adapter-specific template for migrations
    #
    # @param [String] value
    #
    # @return [String]
    #
    def self.template(value = NOTHING)
      @template = value unless value.equal?(NOTHING)
      @template || DEFAULT_TEMPLATE
    end

    # @!attribute [r] gateway
    #
    # @return [ROM::Gateway] the gateway to persistence
    #
    attr_reader :gateway

    # @!attribute [r] paths
    #
    # @return [String] the list of paths containing migrations
    #
    attr_reader :paths

    # @!attribute [r] logger
    #
    # @return [::Logger] the logger used to log results of applying migrations
    #
    attr_reader :logger

    # Initializes the migrator with reference to the gateway and list of
    # paths containing migrations.
    #
    # @param [ROM::Gateway] gateway
    # @option options [String, Array<String>] :paths
    #   The list of paths to folders containing migrations.
    #   Uses [.default_path] by default.
    # @option options [String] :path
    #   The same as `:paths` (added for compatibility to 'rom-sql')
    # @option options [::Logger] :logger
    #   The custom logger to be used instead of default (that logs to +$stdout+)
    #
    def initialize(gateway, options = {})
      default_path = self.class.default_path
      @paths       = Array(options[:paths] || options[:path] || default_path)
      @logger      = options[:logger] || Logger.new
      @gateway     = gateway

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
    #   migrator.create_file(
    #     path:   "spec/dummy/db/migrate",
    #     klass:  "Users::Create",
    #     number: "1"
    #   )
    #   # => "spec/dummy/db/migrate/users/1_create.rb"
    #
    # @example Uses the first of migration paths by default
    #   migrator = gateway.migrator paths: ["db/migrate", "spec/dummy/db"]
    #   migrator.create_file(
    #     klass:  "Users::Create",
    #     number: "1"
    #   )
    #   # => "db/migrate/users/1_create.rb"
    #
    # @example Provides the number using [#next_migration_number]
    #   migrator.create_file(
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
    def create_file(options)
      Generator.call self, { path: paths.first }.merge(options)
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
