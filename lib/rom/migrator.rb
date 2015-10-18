# encoding: utf-8

require "immutability"
require "logger"
require "rom"

module ROM

  require_relative "migrator/errors"     # gem-specific errors
  require_relative "migrator/logger"     # default logger for migration
  require_relative "migrator/settings"   # adapter-specific settings
  require_relative "migrator/registrar"  # registers migrations
  require_relative "migrator/migration"  # changes the persistence
  require_relative "migrator/migrations" # defines the order of migrations
  require_relative "migrator/source"     # describes sources for migrations
  require_relative "migrator/sources"    # filters sources by their numbers
  require_relative "migrator/generator"  # scaffolds a migration
  require_relative "migrator/class_dsl"  # sets registrar and settings

  # The abstract base class for adapter-specific migrators
  #
  # The migrator stores all adapter-specific settings and provides methods to:
  # - [#apply] migrations
  # - [#reverse] migrations
  # - [#create_file] with migration
  # - declare custom [.migration]
  # - instantiate unnumbered [#migration]
  #
  # @author nepalez <andrew.kozin@gmail.com>
  #
  # @abstract
  #
  class Migrator

    # defines `.settings`, `.registrar` and `.migration`
    # along with helpers customizing settings and registrar.
    extend ClassDSL

    # @private
    attr_reader :gateway, :registrar, :template, :logger, :paths, :counter

    # Initializes the migrator with reference to the gateway.
    #
    # @param [ROM::Gateway] gateway
    # @option options [Array<String>] :paths
    #   Custom paths to migrations
    # @option options [String] :path
    #   Custom path to migrations (alternative to :paths)
    # @option options [::Logger] :logger
    #   The custom logger to be used instead of default (that logs to +$stdout+)
    #
    def initialize(gateway, options = {})
      default    = self.class.settings
      @template  = options.fetch(:template) { default.template }
      @counter   = options.fetch(:counter)  { default.counter }
      @logger    = options.fetch(:logger)   { default.logger }
      @paths     = options[:paths] || [options.fetch(:path) { default.path }]
      @gateway   = gateway
      @registrar = self.class.registrar.new(gateway)
    end

    # Returns a number for the next migration
    #
    # @return [String]
    #
    def next_number
      counter.call(files.last_number).to_s
    end

    # Defines and instantiates unnumbered migration object,
    # using a block to customize the migration's +up+ and +down+ methods.
    #
    # @param [Proc] block The block describing a migration
    # @param [String] number The number for the migration
    #
    # @return [ROM::Migrator::Migration]
    #
    def migration(number = nil, &block)
      klass = self.class.migration(&block)
      klass.new migration_options.merge(number: number || next_number)
    end

    # Applies migrations
    #
    # @param [Hash] options
    # @option options [nil, #to_s] :target The target version
    #
    # @return [undefined]
    #
    def apply(options = {})
      target = options[:target]
      files
        .after_numbers(registrar.registered)
        .upto_number(target)
        .to_migrations(migration_options)
        .apply
    end

    # @!method reverse(target = nil, options = {})
    # Reverses migrations
    #
    # @param [Hash] options
    # @option options [nil, #to_s] :target The target version
    # @option options [Boolean] :allow_missing_files
    #   Whether reversion should continue if some registered files are missed
    #
    # @return [undefined]
    #
    def reverse(options = {})
      target, skip = options.values_at(:target, :allow_missing_files)
      files
        .with_numbers(registrar.registered, !skip)
        .after_numbers(target)
        .to_migrations(migration_options)
        .reverse
    end

    # Generates the migration
    #
    # @param [Hash] options
    # @option (see ROM::Migrator::Generator.call)
    #
    # @return (see ROM::Migrator::Generator.call)
    #
    def create_file(options = {})
      defaults = {
        path:     paths.first,
        logger:   logger,
        template: template,
        number:   next_number
      }
      Generator.call defaults.merge(options)
    end

    private

    def files
      Sources.from_folders(paths)
    end

    def migration_options
      { gateway: gateway, logger: logger, registrar: registrar }
    end

  end # class Migrator

end # module ROM
