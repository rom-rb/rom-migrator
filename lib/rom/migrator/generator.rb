# encoding: utf-8

module ROM

  class Migrator

    # Scaffolds next migration
    #
    # Uses the migrator to define the next migration number and
    # adapter-specific template
    #
    # @api private
    #
    # @author nepalez <andrew.kozin@gmail.com>
    #
    class Generator

      include ROM::Options, Immutability

      option :logger,   reader: true
      option :name,     reader: true
      option :number,   reader: true
      option :path,     reader: true, coercer: File.method(:expand_path)
      option :template, reader: true, coercer: File.method(:expand_path)

      # @private See [#initialize]
      attr_reader :path, :template

      # @!method initialize(options)
      # Initializes the generator
      #
      # @param [Hash] options
      # @option options [::Logger] :logger Logger that collects results
      # @option options [String, nil] :name Name of the migration
      # @option options [String] :number Migration number (required)
      # @option options [String] :path Path to migration directory
      # @option options [String] :template Path to template
      #
      def initialize(_)
        super
        @target = fullname
      end

      # @!attribute [r] target
      #
      # @return [String] Full name of the file to be created
      #
      attr_reader :target

      # Creates the [#target] and returns its full name
      #
      # @return [String]
      #
      def call
        with_logging do
          FileUtils.mkdir_p path
          FileUtils.copy_file template, target
        end
        target
      end

      # Initializes and calls the generator at once
      #
      # @param  (see #initialize)
      # @option (see #initialize)
      #
      # @return (see #call)
      #
      def self.call(options)
        new(options).call
      end

      private

      def fullname
        basename = [number, Inflector.underscore(name)].compact.join("_")
        File.join(path, basename << ".rb")
      end

      def with_logging
        yield
        logger.info "New migration created at '#{target}'"
      rescue => error
        logger.error "Error occured while creating file '#{target}': #{error}"
        raise
      end

    end # class Generator

  end # class Migrator

end # module ROM
