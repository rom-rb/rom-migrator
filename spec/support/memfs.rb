# Defines fake filesystem when necessary
require "memfs"

RSpec.configure do |c|
  c.around(:each, memfs: true) do |example|
    MemFs.activate do
      example.run
    end
  end
end
