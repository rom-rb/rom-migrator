# encoding: utf-8

module ROM::Migrator::Errors

  # The exception complaining that a migration has already been reversed
  #
  # @author nepalez <andrew.kozin@gmail.com>
  #
  class AlreadyReversedError < RuntimeError

    # Initializes the exception for the wrong number
    #
    # @param [#to_s] number The number of migration
    #
    def initialize(number)
      super <<-MESSAGE
        |Tried to reverse migration with number '#{number}',
        | that either hasn't been applied yet, or has already been reversed.
        |The error can be caused by a concurrent process of another db client,
        | that made change into the migrations registry.
      MESSAGE
    end

  end # class AlreadyReversedError

end # module ROM::Migrator::Errors
