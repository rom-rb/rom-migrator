# encoding: utf-8

describe ROM::Migrator do

  let(:klass)     { Class.new(described_class) }
  let(:generator) { ROM::Migrator::Generator }
  let(:migrator)  { klass.new gateway, options }
  let(:gateway)   { double(:gateway).as_null_object }

  let(:options) do
    { logger: logger, path: path, counter: counter, template: template }
  end
  let(:logger)   { Logger.new StringIO.new }
  let(:counter)  { -> prev { prev.to_i + 2 } }
  let(:path)     { "/db/migrate" }
  let(:template) { "/config/custom" }

  it "uses the DSL" do
    expect(klass).to be_kind_of ROM::Migrator::ClassDSL
  end

  describe ".new" do
    subject { klass.new(gateway) }

    it "can skip options" do
      expect { subject }.not_to raise_error
    end
  end # describe .new

  describe "#gateway" do
    subject { migrator.gateway }

    it { is_expected.to eql gateway }
  end # describe #gateway

  describe "#registrar" do
    subject { migrator.registrar }

    it "instantiates customized registrar" do
      expect(subject).to be_kind_of klass.registrar
    end

    it "uses the gateway" do
      expect(subject.gateway).to eql gateway
    end
  end # describe #registrar

  describe "#logger" do
    subject { migrator.logger }

    it { is_expected.to eql logger }

    context "by default" do
      before { options.delete :logger }

      it "uses default logger" do
        expect(subject).to eql klass.settings.logger
      end
    end
  end # describe #logger

  describe "#template" do
    subject { migrator.template }

    it { is_expected.to eql template }

    context "by default" do
      before { options.delete :template }

      it "uses default logger" do
        expect(subject).to eql klass.settings.template
      end
    end
  end # describe #logger

  describe "#paths" do
    subject { migrator.paths }

    context "when single path is set" do
      it { is_expected.to eql [path] }
    end

    context "when list of paths is set" do
      before { options[:paths] = paths }

      let(:paths) { %w(foo bar) }

      it { is_expected.to eql paths }
    end

    context "by default" do
      before { options.delete :path }

      it "uses default path" do
        klass.default_path "custom"

        expect(subject).to eql ["custom"]
      end
    end
  end # describe #default_path

  describe "#counter" do
    subject { migrator.counter[1] }

    it { is_expected.to eql(3) }

    context "by default" do
      before { options.delete :counter }

      it "uses default counter" do
        time = Time.new(2015, 12, 2, 8, 23, 42.8982)
        Timecop.freeze(time) { expect(subject).to eql "20151202082342898" }
      end
    end
  end # describe #counter

  describe "#next_number", :memfs do
    include_context :migrations
    subject { migrator.next_number }

    it "applies #counter to existing migrations" do
      expect(subject).to eql "5"
    end
  end # describe #next_number

  describe "#create_file" do
    around { |example| Timecop.freeze { example.run } }
    before { allow(generator).to receive(:call) { "new_file.rb" } }

    context "by default" do
      subject { migrator.create_file }

      let(:default_options) do
        {
          template: migrator.template,
          number:   migrator.next_number,
          path:     migrator.paths.first,
          logger:   migrator.logger
        }
      end

      it "builds and calls a generator with default options" do
        expect(generator).to receive(:call).with default_options
        expect(subject).to eql "new_file.rb"
      end
    end

    context "with options" do
      subject { migrator.create_file(explicit_options) }

      let(:explicit_options) do
        { template: "/foo/bar", number: "1", path: "/baz/qux", logger: logger }
      end

      it "builds and calls a generator using options" do
        expect(generator).to receive(:call).with explicit_options
        expect(subject).to eql "new_file.rb"
      end
    end
  end # describe #create_file

  describe "#migration" do
    around { |example| Timecop.freeze { example.run } }
    subject { migrator.migration("foo") { up { :foo } } }

    it "provides custom migration" do
      expect(subject).to be_kind_of ROM::Migrator::Migration
      expect(subject.class.up.call).to eql :foo
    end

    it "uses current logger and registrar" do
      expect(subject.logger).to eql migrator.logger
      expect(subject.registrar).to eql migrator.registrar
    end

    it "uses the number" do
      expect(subject.number).to eql "foo"
    end

    context "without a number" do
      subject { migrator.migration { up { :foo } } }

      it "uses the next number" do
        expect(subject.number).to eql migrator.next_number
      end
    end
  end # describe #migration

  describe "#apply", :memfs do
    include_context :migrations
    before { options[:paths] = %w(/db/migrate /spec/dummy/db/migrate) }
    before { allow(migrator.registrar).to receive(:registered) { %w(1) } }

    context "without :target option" do
      after { migrator.apply }

      it "applies all non-registered migrations" do
        expect(gateway).not_to receive(:go).with "CREATE TABLE users;"
        expect(gateway).to receive(:go).with("CREATE TABLE roles;").ordered
        expect(gateway).to receive(:go).with("CREATE TABLE accounts;").ordered
      end

      it "logs the results" do
        expect(logger).to receive(:info).twice
      end
    end

    context "with :target option" do
      after { migrator.apply target: "2" }

      it "applies non-registered migrations up to the target" do
        expect(gateway).not_to receive(:go).with "CREATE TABLE users;"
        expect(gateway).to receive(:go).with("CREATE TABLE roles;")
        expect(gateway).not_to receive(:go).with("CREATE TABLE accounts;")
      end

      it "logs the results" do
        expect(logger).to receive(:info).once
      end
    end
  end # describe #apply

  describe "#reverse", :memfs do
    include_context :migrations
    before { options[:paths] = %w(/db/migrate /spec/dummy/db/migrate) }
    before { allow(migrator.registrar).to receive(:registered) { %w(1 2) } }

    context "without :target option" do
      after { migrator.reverse }

      it "reverses all registered migrations" do
        expect(gateway).not_to receive(:go).with "DROP TABLE accounts;"
        expect(gateway).to receive(:go).with("DROP TABLE roles;").ordered
        expect(gateway).to receive(:go).with("DROP TABLE users;").ordered
      end

      it "logs the results" do
        expect(logger).to receive(:info).twice
      end
    end

    context "with :target option" do
      after { migrator.reverse target: "1" }

      it "reverses migrations, registered after the target" do
        expect(gateway).not_to receive(:go).with "DROP TABLE accounts;"
        expect(gateway).to receive(:go).with("DROP TABLE roles;").ordered
        expect(gateway).not_to receive(:go).with("DROP TABLE users;")
      end

      it "logs the results" do
        expect(logger).to receive(:info).once
      end
    end

    context "without :allow_missing_files option" do
      subject { migrator.reverse }
      before { allow(migrator.registrar).to receive(:registered) { %w(1 2 5) } }

      it "fails" do
        expect { subject }.to raise_error RuntimeError
      end
    end

    context "with :allow_missing_files option" do
      after { migrator.reverse allow_missing_files: true }
      before { allow(migrator.registrar).to receive(:registered) { %w(1 2 5) } }

      it "reverses migrations" do
        expect(gateway).not_to receive(:go).with "DROP TABLE accounts;"
        expect(gateway).to receive(:go).with("DROP TABLE roles;").ordered
        expect(gateway).to receive(:go).with("DROP TABLE users;").ordered
      end

      it "logs the results" do
        expect(logger).to receive(:info).exactly(3).times
      end
    end
  end # describe #reverse

end # describe ROM::Migrator
