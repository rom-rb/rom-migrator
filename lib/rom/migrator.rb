# encoding: utf-8

require "immutability"
require "logger"
require "rom"

module ROM

  require_relative "migrator/functions"       # pure functions
  require_relative "migrator/errors"          # gem-specific errors

  require_relative "migrator/logger"          # default logger for migration
  require_relative "migrator/migration"       # changes the persistence
  require_relative "migrator/migrations"
  require_relative "migrator/migration_file"  # file description
  require_relative "migrator/migration_files" # filterable collection of files
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
  #       gateway.send "SELECT number FROM migrations;"
  #     end
  #
  #     # registers new applied migration
  #     def register(number)
  #       gateway.send "INSERT number '#{number}' INTO migrations;"
  #     end
  #
  #     # unregisters a migration being reversed
  #     def unregister(number)
  #       gateway.send "DELETE FROM migrations WHERE number='#{number}';"
  #     end
  #
  #     # other function to be accessible from migration's +#up+ and +#down+
  #     def where(options)
  #       gateway.where(options)
  #     end
  #   end
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

    # @!attribute [r] default_path
    #
    # @return [String] default path to migrations
    #
    attr_reader :default_path

    # @!attribute [r] template
    #
    # @return [String] default path to migration's template
    #
    attr_reader :template

    # Initializes the migrator with reference to the gateway
    #
    # @param [ROM::Gateway] gateway
    #
    def initialize(gateway)
      @gateway      = gateway
      @default_path = self.class.default_path
      @template     = self.class.template
      prepare_registry
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

    # Applies migrations
    #
    # @option options [String, nil] :target
    #   The target version to migrate. The migrator will apply all existing
    #   versions, whose numbers are **less or equal** to given one.
    #   When the target is not provided, the migrator will apply all existing
    #   migrations.
    # @option options [Array<String>] :folders
    #   The paths to migration folders. The migrator will use either these
    #   ones, or default path, to look for migrations.
    # @option options [::Logger] :logger
    #   The mutable IO object to log results of migrations
    #   By default uses an instance of [ROM::Migrator::Logger]
    #
    # @return [self] itself
    #
    def apply(options)
      options[:logger] ||= Logger.new
      Runner.apply options.merge(migrator: self)
      self
    end

    # Reverses migrations
    #
    # @option options [String] :target
    #   The target version to migrate. The migrator will reverse all
    #   registered migrations whose numbers are **greater** than given one.
    #   When the target is not provided, the migrator will reverse all
    #   registered (previously applied) migrations.
    # @option options [Array<String>] :folders
    #   The paths to migration folders. The migrator will use either these
    #   ones, or default path, to look for migrations.
    # @option options [::Logger] :logger
    #   The mutable IO object to log results of migrations
    #   By default uses an instance of [ROM::Migrator::Logger]
    #
    # @return [self] itself
    #
    def reverse(options)
      options[:logger] ||= Logger.new
      Runner.reverse options.merge(migrator: self)
      self
    end

    # Generates the migration
    #
    # @example
    #   # Suppose the current time is 08.02.2016 13:39:17
    #   migrator.generate(
    #     folders: ["db/migrate", "spec/dummy/db/migrate"],
    #     klass:   "Users::Create"
    #   )
    #   # creates "db/migrate/users/20160208133917843_create.rb"
    #
    # @option options [String] :klass
    #   The name of the migration klass in any case (either camel, or snake).
    #   The camelized value will be send to template along with adapter.
    #   It is also used to provide the relative path to template from
    #   the target folder.
    # @option options [Array<String>] :folders
    #   The paths to migration folders. The migrator will use either these
    #   ones, or default path, to look for the maximum number of
    #   existing migrations.
    #   The order of folders is sufficient, because the generated migration
    #   will be placed to the **first** folder.
    #   By default it is set to the adapter-specific [.default_path].
    # @option options [String] :number
    #   The forced number of the migration.
    #   If the number is not set, it will be generated by migrator
    #   using [#next_migration_number] counter and last number of migrations
    #   from +:folders+
    #
    # @return [self] itself
    #
    def generate(options)
      opts = { folders: [default_path] }.merge(options).merge(migrator: self)
      Generator.call(opts)

      self
    end

    # Defines and instantiates unnamed migration to be applied/reversed
    #
    # @param [Proc] block The migration definition (via +up+ and +down+ methods)
    #
    # @return [ROM::Migrator::Migration]
    #
    def migration(options = {}, &block)
      logger = options.fetch(:logger) {}
      Class.new(Migration, &block).new(migrator: self, logger: logger)
    end

    private

    def method_missing(*args)
      gateway.public_send(*args)
    end

    def respond_to_missing?(name, *)
      gateway.respond_to? name
    end

  end # class Migrator

end # module ROM
