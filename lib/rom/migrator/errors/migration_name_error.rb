# encoding: utf-8

module ROM::Migrator::Errors

  # The exception complaining about invalid name of migration
  #
  # @author nepalez <andrew.kozin@gmail.com>
  #
  class MigrationNameError < ::NameError

    include Immutability

    # Initializes the exception for the wrong path
    #
    # @param [#to_s] path
    #
    def initialize(path)
      super "'#{path}' is not a valid migration"
    end

  end # class MigrationNameError

end # module ROM::Migrator::Errors
