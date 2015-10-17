# encoding: utf-8

class ROM::Migrator

  # Readonly collection of migrations
  #
  # Responcible for applying / reversing migrations in a proper order.
  #
  # @author nepalez <andrew.kozin@gmail.com>
  #
  class Migrations

    include Enumerable

    # Initializes a collection by array of migrations
    #
    # @param [Array<ROM::Migrator::Migration>] migrations
    #
    def initialize(*migrations)
      @migrations = migrations.flatten
    end

    # Iterates through migrations
    #
    # @return [Enumerator<ROM::Migrator::Migration>]
    #
    # @yieldparam [ROM::Migrator::Migration] migration
    #
    def each
      block_given? ? @migrations.each { |migration| yield(migration) } : to_enum
    end

    # Applies all migrations
    #
    # @return [self] itself
    #
    def apply
      sort_by(&:number).each(&:apply)
      self
    end

    # Reverses all migrations
    #
    # @return [self] itself
    #
    def reverse
      sort_by(&:number).reverse_each(&:reverse)
      self
    end

  end # class Migrations

end # class ROM::Migrator
