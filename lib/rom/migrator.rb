# encoding: utf-8

require "rom"
require "immutability"

module ROM

  # The abstract base class for ROM migrators
  #
  # The migrator stores all adapter-specific settings
  # and defines APIwith 3 instance methods to:
  # - [#apply] migrations
  # - [#rollback] migrations
  # - [#generate] the next migration
  #
  # @example
  #   class ROM::Custom::Migrator < ROM::Migrator
  #     # default path to migrations folder
  #     default_path "db/migrate"
  #
  #     # path to adapter-specific template for scaffolding a migration
  #     template File.expand_path("../template.erb", __FILE__)
  #
  #     private
  #
  #     # counts number for the next migration
  #     def next_migration_number(last_number)
  #       last_number.to_i + 1
  #     end
  #
  #     # returns numbers of applied migrations
  #     def registered
  #       gateway.send "SELECT number FROM migrations;"
  #     end
  #
  #     # registers new applied migration
  #     def register(number)
  #       gateway.send "INSERT number '#{number}' INTO migrations;"
  #     end
  #
  #     # unregisters a migration being rolled back
  #     def unregister(number)
  #       gateway.send "DELETE FROM migrations WHERE number='#{number}';"
  #     end
  #
  #     # other function to be accessible from migration's +#up+ and +#down+
  #     def where(options)
  #       gateway.where(options)
  #     end
  #   end
  #
  # @author nepalez <andrew.kozin@gmail.com>
  #
  # @abstract
  #
  class Migrator

  end # class Migrator

end # module ROM
