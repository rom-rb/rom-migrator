# encoding: utf-8

class ROM::Migrator

  # Adapter-speficic decorator of the gateway that registers migrations
  # and returns numbers of the applied migrations.
  #
  # Its abstract methods should be implemented (reloaded)
  # inside a concrete adapter via [ROM::Migrator::ClassDSL].
  #
  # @api private
  #
  # @author nepalez <andrew.kozin@gmail.com>
  #
  class Registrar

    include Errors

    # @private
    attr_reader :gateway

    # Prepares a registry by creating necessary tables, indexes etc.
    #
    # @return [undefined]
    #
    # @abstract
    #
    def prepare_registry; end

    # @!method register(number)
    # Registers a number of migration, that has been applied
    #
    # @param [number]
    #
    # @return [undefined]
    #
    # @abstract
    #
    def register(_); end

    # @!method unregister(number)
    # Unegisters a number of migration, that has been reversed
    #
    # @param [number]
    #
    # @return [undefined]
    #
    # @abstract
    #
    def unregister(_); end

    # Checks whether a migration number has already been applied
    #
    # @param [String] number
    #
    # @return [Boolean]
    #
    # @abstract
    #
    def registered?(number)
      registered.include? number
    end

    # Returns an array of numbers of migrations that has been applied
    #
    # @return [Array<String>]
    #
    # @abstract
    #
    def registered
      []
    end

    # Initializes a registrar for given gateway and prepares the registry
    #
    # @param [ROM::Gateway] gateway
    #
    def initialize(gateway)
      @gateway = gateway
      @mutex   = Mutex.new
      @mutex.synchronize { prepare_registry }
    end

    # Yields the block and registers the number if it hasn't been registered yet
    #
    # @param [#to_s] number
    #
    # @return [undefined]
    #
    # @raise [AlreadyAppliedError] if the number is already registered
    #
    def apply(number)
      return yield unless number
      @mutex.synchronize do
        fail AlreadyAppliedError[number] if registered?(number)
        yield
        register number
      end
    end

    # Yields the block and unregisters the number if it has been registered
    #
    # @param [#to_s] number
    #
    # @return [undefined]
    #
    # @raise [AlreadyAppliedError] if the number hasn't been registered
    #
    def reverse(number)
      return yield unless number
      @mutex.synchronize do
        fail AlreadyReversedError[number] unless registered?(number)
        yield
        unregister number
      end
    end

    private

    def method_missing(*args)
      @gateway.public_send(*args)
    end

    def respond_to_missing?(*args)
      @gateway.respond_to?(*args)
    end

  end # class Registrar

end # class ROM::Migrator
