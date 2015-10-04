# encoding: utf-8

class ROM::Migrator

  # Base class for migrations that make changes to persistence
  #
  # @example
  #   migration = ROM::Migrator::Migration.new number: "1", migrator: migrator
  #
  # @api public
  #
  # @abstract
  #
  # @author nepalez <andrew.kozin@gmail.com>
  #
  class Migration

    include ROM::Options

    option :migrator, reader: true
    option :number,   reader: true

    # Applies the migration and then registers in in the gateway
    #
    # @param [::Logger] logger
    #
    # @return [undefined]
    #
    def apply(logger)
      up
      register number
      logger.info "Migration number '#{number}' has been applied"
    rescue => error
      logger.error "An error occured while applying" \
                   " migration number '#{number}':\n#{error}"
      raise
    end

    # Rolls back the migration and unregisters it the gateway
    #
    # @param [::Logger] logger
    #
    # @return [undefined]
    #
    def rollback(logger)
      down
      unregister number
      logger.info "Migration number '#{number}' has been rolled back"
    rescue => error
      logger.error "An error occured while rolling back" \
                   " migration number '#{number}':\n#{error}"
      raise
    end

    # Applies the migration
    #
    # @abstract
    #
    # @return [undefined]
    #
    def up; end

    # Rolls back the migration
    #
    # @abstract
    #
    # @return [undefined]
    #
    def down; end

    private

    # Migrator should provide methods to access persistence
    def method_missing(*args)
      migrator.public_send(*args)
    end

    def respond_to_missing?(*args)
      migrator.respond_to?(*args)
    end

  end # class Migration

end # class ROM::Migrator
