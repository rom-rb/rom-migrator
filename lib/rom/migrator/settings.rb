# encoding: utf-8

class ROM::Migrator

  # Frozen container for the adapter-specific migrator settings
  #
  # @api private
  #
  # @author nepalez <andrew.kozin@gmail.com>
  #
  class Settings

    # @!attribute [r] path
    #
    # @return [String] default path to migrations
    #
    attr_reader :path

    # @!attribute [r] path
    #
    # @return [String] default path to migration template
    #
    attr_reader :template

    # @!attribute [r] logger
    #
    # @return [::Logger] default logger
    #
    attr_reader :logger

    # @!attribute [r] counter
    #
    # @return [Proc] method that counts the next migraion number
    #
    attr_reader :counter

    # Initializes the settings
    #
    def initialize
      @path     = "db/migrate"
      @template = File.expand_path "../template.txt", __FILE__
      @logger   = Logger.new
      @counter  = -> _ { Time.now.strftime "%Y%m%d%H%M%S%L" }
    end

    # Customizes the default path to migrations and returns updated settings
    #
    # @param [#to_s] path
    #
    # @return [ROM::Migrator::Settings]
    #
    def default_path(path)
      update { @path = path }
    end

    # Customizes the path to migration template and returns updated settings
    #
    # @param [#to_s] template
    #
    # @return [ROM::Migrator::Settings]
    #
    def default_template(template)
      update { @template = template }
    end

    # Customizes the logger and returns updated settings
    #
    # @param [::Logger] logger
    #
    # @return [ROM::Migrator::Settings]
    #
    def default_logger(logger)
      update { @logger = logger }
    end

    # Customizes how the next migration number should be count
    #
    # @param [Proc] fn
    #
    # @return [ROM::Migrator::Settings]
    #
    def default_counter(&fn)
      update { @counter = fn }
    end

    private

    # Returns a new object with some updates
    #
    def update(&block)
      dup.tap { |instance| instance.instance_eval(&block) }
    end

  end # module Settings

end # class ROM::Migrator
