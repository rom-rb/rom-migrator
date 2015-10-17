# encoding: utf-8

class ROM::Migrator

  # Default Logger for the migrator
  #
  # @example
  #   logger = Logger.new
  #   logger.info "some text"
  #   # => some text
  #
  class Logger < ::Logger

    # Instantiates the logger
    #
    def initialize
      super $stdout
      self.formatter = -> _, _, _, message { "#{message.lines.join("  ")}\n" }
    end

  end # Logger

end # class ROM::Migrator
