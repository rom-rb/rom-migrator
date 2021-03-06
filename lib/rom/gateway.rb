# encoding: utf-8

module ROM

  # @todo Move this monkey-patching directly to `Gateway#migrator` in `rom`
  # Adds migrator to gateway instance
  #
  # @author nepalez <andrew.kozin@gmail.com>
  #
  class Gateway

    # Returns a migrator that decorates the gateway
    #
    # @param [Hash] options
    # @option (see ROM::Migrator#initializer)
    #
    # @return [ROM::Migrator]
    #
    def migrator(options = {})
      ROM.adapters.fetch(adapter)::Migrator.new(self, options)
    rescue KeyError
      raise AdapterNotPresentError.new(adapter, :migrator)
    rescue NameError
      raise MigratorNotPresentError.new(adapter)
    end

    # The exception to be raised when adapter-specific gateway tries to use
    # a migrator in case the adapter doesn't include it.
    #
    # @example
    #   MigratorNotPresentError.new :custom_adapter
    #
    class MigratorNotPresentError < NameError
      # Initializes exception with adapter-specific error message
      #
      # @param [#to_s] adapter
      #
      def initialize(adapter)
        super "The #{adapter} adapter doesn't contain a migrator"
      end
    end

  end # class Gateway

end # module ROM
