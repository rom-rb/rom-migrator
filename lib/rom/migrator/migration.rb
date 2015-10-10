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
  #   migration = CreateUsers.new(migrator) # using some migrator
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

    include ROM::Options

    option :number,   reader: true
    option :migrator, reader: true, required: true
    option :logger,   reader: true

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
    # Initializes the migration for some migrator
    #
    # The migrator provides custom methods to make changes to persistence.
    # Because it calls <potentially> stateful connection
    # (migration --> migrator --> generator --> connection),
    # a mutex is used for thread safety.
    #
    # When migration is initialized with a number, its appying and reversing
    # is registered to persistence. Otherwise it just changes the
    # persistence without any possibility to step back.
    #
    # @param [Hash] options
    # @option options [ROM::Migrator] :migrator
    #   Required migrator that provides access to persistence.
    # @option options [#to_s] :number
    #   Optional number of the migration.
    # @option options [::Logger] :logger
    #   Custom logger to which the migration reports its results
    #
    def initialize(_)
      super
      @up       = self.class.up
      @down     = self.class.down
      @logger ||= Logger.new
      @mutex    = Mutex.new
      freeze
    end

    # Applies the migration to persistence
    #
    # If the [#number] was provided, then registers it in the persistence
    #
    # @return [self] itself
    #
    def apply
      run_threadsafe_and_log_as :applied do
        instance_eval(&@up)
        register(number) if number
      end
    end

    # Reverses the migration in persistence
    #
    # If the [#number] wasn't provided, then unregisters its in the persistence
    #
    # @return [self] itself
    #
    def reverse
      run_threadsafe_and_log_as :reversed do
        instance_eval(&@down)
        unregister(number) if number
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

    # All methods, used by [.up] and [.down], are forwarded to the migrator
    def method_missing(*args)
      @migrator.public_send(*args)
    end

    def respond_to_missing?(*args)
      @migrator.respond_to?(*args)
    end

    def run_threadsafe_and_log_as(done, &block)
      @mutex.synchronize { run_and_log_as(done, &block) }
      self
    end

    def run_and_log_as(done)
      yield
      logger.info "The #{self} has been #{done}"
    rescue => error
      logger.error "The error occured when #{self} was #{done}:\n#{error}"
      raise
    end

  end # class Migration

end # class ROM::Migrator
