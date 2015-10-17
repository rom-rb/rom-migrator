# encoding: utf-8

module ROM::Migrator::Errors

  # The gem-specific extension of runtime error
  #
  # @author nepalez <andrew.kozin@gmail.com>
  #
  class RuntimeError < ::RuntimeError

    # Alias for the exception's constructor
    #
    # @param [Object, Array<Object>] args
    #
    # @return [ROM::Migrator::Errors::Base]
    #
    def self.[](*args)
      new(*args)
    end

    # Removes tabs from multiline error messages
    #
    # @param [String] message
    #
    def initialize(message)
      super message.gsub(/\n *\| (?=[^ ])/, " ").gsub(/ *\|/, "")
    end

  end # class NotFoundError

end # module ROM::Migrator::Errors
