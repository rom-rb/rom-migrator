# encoding: utf-8

module ROM

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
    end

  end # class Gateway

end # module ROM
