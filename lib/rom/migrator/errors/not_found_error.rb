# encoding: utf-8

module ROM::Migrator::Errors

  # The exception complaining that migration file with some number wasn't found
  #
  # @author nepalez <andrew.kozin@gmail.com>
  #
  class NotFoundError < ::IOError

    # Initializes the exception for the wrong number
    #
    # @param [#to_s] number The number of migration
    # @param [Array<#to_s>] folders The list of folders to look for migration
    #
    def initialize(number, *folders)
      list = folders.map { |folder| "\n- '#{folder}'" }.join(",")
      super "migration number '#{number}' wasn't found in folders:#{list}"
    end

  end # class NotFoundError

end # module ROM::Migrator::Errors
