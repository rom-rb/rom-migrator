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
    # @return [ROM::Migrator]
    #
    def migrator
      ROM.adapters.fetch(adapter)::Migrator.new(self)
    rescue KeyError
      raise AdapterNotPresentError.new(adapter, :migrator)
    rescue NameError
      raise MigratorNotPresentError.new(adapter)
    end

    class MigratorNotPresentError < NameError
      include Immutability

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
