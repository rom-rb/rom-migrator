# Defines fake filesystem when necessary
require "memfs"

RSpec.configure do |c|
  c.around(:each, memfs: true) do |example|
    MemFs.activate do
      # This is a hack for #require to use a fake FS
      ROM::Migrator::MigrationFile.send :define_method, :require do |name|
        eval File.read(name)
      end
      # This is a hack for #require to use a fake FS
      ROM::Migrator::MigrationFile.send :define_method, :load do |name|
        require name
      end

      example.run
    end
  end
end
