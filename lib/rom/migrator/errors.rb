# encoding: utf-8

class ROM::Migrator

  # Collection of gem-specific exceptions
  #
  # @author nepalez <andrew.kozin@gmail.com>
  #
  module Errors

    require_relative "errors/migration_name_error"
    require_relative "errors/not_found_error"

  end # module Errors

end # class ROM::Migrator
