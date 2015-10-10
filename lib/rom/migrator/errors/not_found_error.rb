# encoding: utf-8

module ROM::Migrator::Errors

  # The exception complaining that migration file with some number wasn't found
  #
  # @author nepalez <andrew.kozin@gmail.com>
  #
  class NotFoundError < ::IOError

    include Immutability

    # Initializes the exception for the wrong number
    #
    # @param [#to_s] number The number of migration
    #
    def initialize(number)
      super "Cannot find migration with number '#{number}'"
    end

  end # class NotFoundError

end # module ROM::Migrator::Errors
