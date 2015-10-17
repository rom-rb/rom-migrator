# encoding: utf-8

module ROM::Migrator::Errors

  # The exception complaining that a migration has already been applied
  #
  # @author nepalez <andrew.kozin@gmail.com>
  #
  class AlreadyAppliedError < RuntimeError

    # Initializes the exception for the wrong number
    #
    # @param [#to_s] number The number of migration
    #
    def initialize(number)
      super <<-MESSAGE
        |Tried to apply migration with number '#{number}',
        | that has already been applied.
        |The error can be caused by a concurrent process of another db client,
        | that made change into the migrations registry.
      MESSAGE
    end

  end # class AlreadyAppliedError

end # module ROM::Migrator::Errors
