# encoding: utf-8

class ROM::Migrator

  # Module Functions provides the collection of gem-specific pure functions
  # to extract migration parameters from its name or path
  #
  # @author nepalez <andrew.kozin@gmail.com>
  #
  module Functions

    extend Transproc::Registry
    import :camelize,    from: ROM::Inflector, as: :up
    import :underscore,  from: ROM::Inflector, as: :down
    import :constantize, from: ROM::Inflector

    # Regex to split path by parts
    SPLITTER = %r{^(?:(.+)(?:\/))?([^_\/]+)(?:_)([^.\/]+)(?:\.rb)$}

    # Extracts [name, number] from migration path
    #
    # @example
    #   fn = ROM::Migrator::Functions[:path_to_parts]
    #
    #   fn["foo/bar/baz_qux.rb"] # => ["Foo::Bar::Qux", "baz"]
    #   fn["baz_qux.rb"]         # => ["Qux", "baz"]
    #   fn["qux.rb"]             # => [nil, nil]
    #
    # @param [String] path
    #
    # @return [<type>] <description>
    #
    def self.path_to_parts(path)
      dir, number, name = split_path(path)
      return [nil, nil] unless number

      klass = [dir, name].compact.join("/")
      [fetch(:up)[klass], number]
    end

    # Builds migration path from name and number
    #
    # @example
    #   fn = ROM::Migrator::Functions[:path_to_parts]
    #
    #   fn["Foo::Bar::Qux", "baz"] # => "foo/bar/baz_qux.rb"
    #   fn["Qux", "baz"]           # => "baz_qux.rb"
    #   fn[nil, "baz"]             # => "baz_.rb"
    #   fn["Qux", nil]             # => "_qux.rb"
    #
    # @param [Array<#to_s>] parts
    #
    # @return [String]
    #
    def self.parts_to_path(*parts)
      name, number = parts.flatten
      names = fetch(:down)[name.to_s].split("/")
      names.push("#{number}_#{names.pop}.rb").join("/")
    end

    # Converts input array into flat compact ordered one
    #
    # @example
    #   fn = ROM::Migrator::Functions[:clean_array]
    #
    #   fn[["3", [nil, "2"], "1"]] # => ["1", "2", "3"]
    #
    # @param [Array] array
    #
    # @return [Array] array
    #
    def self.clean_array(array)
      array.flatten.compact.sort
    end

    # @private
    def self.split_path(path)
      path.match(SPLITTER).to_a.values_at(1..3)
    end

  end # module Functions

end # class ROM::Migrator
