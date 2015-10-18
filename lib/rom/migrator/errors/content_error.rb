# encoding: utf-8

module ROM::Migrator::Errors

  # The exception complaining that a file doesn't define a valid migration
  #
  # @author nepalez <andrew.kozin@gmail.com>
  #
  class ContentError < RuntimeError

    # Initializes the exception for a filepath and result of loading.
    #
    # @param [#to_s] number The number of migration
    #
    def initialize(number)
      super <<-MESSAGE
        |The definition of migration number '#{number}' is not valid.
        |Expected a file to return a subclass of ROM::Migrator::Migration:
        |
        |    ROM::Migrator.migration do
        |      up do
        |        # some definitions here
        |      end
        |
        |      down do
        |        # some definitions here
        |      end
        |    end
        |
      MESSAGE
    end

  end # class ContentError

end # module ROM::Migrator::Errors
