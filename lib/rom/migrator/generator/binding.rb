# encoding: utf-8

class ROM::Migrator

  class Generator

    # Simple structure with the only +@klass+ variable to be bound to a template
    #
    # @author nepalez <andrew.kozin@gmail.com>
    #
    class Binding

      # Builds and returns a binding for the template
      #
      # @param [String] klass The migration class
      #
      # @return [::Binding]
      #
      def self.[](klass)
        new(klass).bind
      end

      # Initializes the structure
      #
      # @param [String] klass The migration class
      #
      def initialize(klass)
        @klass = klass
      end

      # Returns the binding of the instance
      #
      # @return [::Binding]
      #
      def bind
        binding
      end

    end # class Binding

  end # class Generator

end # class ROM::Migrator
