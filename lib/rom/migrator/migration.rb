# encoding: utf-8

class ROM::Migrator

  # Base class for migrations
  #
  # @example
  #   class CreateUsers < ROM::Migrator::Migration
  #     up do
  #       create_table(:users).add(name: :text, age: :int)
  #     end
  #
  #     down do
  #       drop_table(:users)
  #     end
  #   end
  #
  #   migration = CreateUsers.new(gateway) # using some gateway
  #   migration.apply
  #   migration.reverse
  #
  # @api public
  #
  # @abstract
  #
  # @author nepalez <andrew.kozin@gmail.com>
  #
  class Migration

    include ROM::Options, Errors
    option :gateway,   reader: true
    option :logger,    reader: true
    option :number,    reader: true
    option :registrar, reader: true

    # Gets or sets the block to be called when the migration is applied
    #
    # @abstract
    #
    # @return [Proc]
    #
    def self.up(&block)
      block ? (@up = block) : @up
    end

    # Gets or sets the block to be called when the migration is reversed
    #
    # @abstract
    #
    # @return [Proc]
    #
    def self.down(&block)
      block ? (@down = block) : @down
    end

    # @!method initialize(options)
    # Initializes the migration for some gateway
    #
    # The gateway provides custom methods to make changes to persistence.
    # Because it calls <potentially> stateful connection
    # (migration --> gateway --> generator --> connection),
    # a mutex is used for thread safety.
    #
    # When migration is initialized with a number, its appying and reversing
    # is registered to persistence. Otherwise it just changes the
    # persistence without any possibility to step back.
    #
    # @param [Hash] options
    # @option options [ROM::Gateway] gateway
    #   The gateway that provides access to persistence.
    # @option options [ROM::Migrator::Registrar] registrar
    #   The object responcible for registering applied migrations.
    # @option options [::Logger] :logger
    #   The logger to store results of migration.
    # @option options [#to_s] :number
    #   The optional number of the migration.
    #
    def initialize(_)
      super
      @up   = self.class.up
      @down = self.class.down
    end

    # Applies the migration to persistence
    #
    # If the [#number] was provided, then registers it in the persistence
    #
    # @return [self] itself
    #
    def apply
      with_logging(:applied) do
        registrar.apply(number) { gateway.instance_eval(&@up) }
      end
    end

    # Reverses the migration in persistence
    #
    # If the [#number] wasn't provided, then unregisters its in the persistence
    #
    # @return [self] itself
    #
    def reverse
      with_logging(:reversed) do
        registrar.reverse(number) { gateway.instance_eval(&@down) }
      end
    end

    # Describes the migration
    #
    # @return [String]
    #
    def to_s
      number ? "migration number '#{number}'" : "migration"
    end

    private

    def with_logging(done)
      yield
      logger.info "The #{self} has been #{done}"
      self
    rescue => error
      logger.error "The error occured when #{self} was #{done}: #{error}"
      raise
    end

  end # class Migration

end # class ROM::Migrator
