# encoding: utf-8

class ROM::Migrator

  # Migrator class DSL
  #
  # @api private
  #
  module ClassDSL

    # Returns a container of adapter-specific settings
    #
    # @return [ROM::Migrator::Settings]
    #
    def settings
      @settings ||= Settings.new
    end

    # Returns the adapter-specific subclass of the base registrar
    #
    # After instantiation, its instance methods can be reload
    # via [#method_missing].
    #
    # @return [Class]
    #
    def registrar
      @registrar ||= Class.new(Registrar)
    end

    # Builds new subclass of base migration using a block
    #
    # @param [Proc] block
    #   Block containing the definition for the migration
    #
    # @return [Class]
    #
    def migration(&block)
      Class.new(Migration, &block)
    end

    private

    SETTINGS_HELPERS =
      [:default_path, :default_template, :default_logger, :default_counter]
      .freeze

    REGISTRAR_HELPERS =
      [:prepare_registry, :register, :unregister, :registered?, :registered]
      .freeze

    def method_missing(*args, &block)
      update_settings(*args, &block) || update_registrar(*args, &block) || super
    end

    def update_settings(name, *args, &block)
      return unless SETTINGS_HELPERS.include? name
      @settings = settings.public_send(name, *args, &block)
    end

    def update_registrar(name, *, &block)
      return unless block && REGISTRAR_HELPERS.include?(name)
      registrar.__send__(:define_method, name, &block)
    end

  end # module ClassDSL

end # module ROM::Migrator
