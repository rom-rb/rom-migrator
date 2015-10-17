# encoding: utf-8

module ROM::Migrator::Errors

  # The exception complaining that a file doesn't define a valid migration
  #
  # @author nepalez <andrew.kozin@gmail.com>
  #
  class ContentError < RuntimeError

    # Initializes the exception for a filepath and result of loading.
    #
    # @param [#to_s] path The path to the file
    # @param [Object] error The result of loading a file
    #
    def initialize(path, result)
      super <<-MESSAGE
        |File '#{path}' doesn't define a migration properly.
        |  Expected a migration file to return a subclass of ROM::Migration:
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
        |  Actual result of loading: #{result.inspect}
        |
      MESSAGE
    end

  end # class ContentError

end # module ROM::Migrator::Errors
