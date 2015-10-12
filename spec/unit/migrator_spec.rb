# encoding: utf-8

require "rom"
require "timecop"

describe ROM::Migrator do

  let(:klass)     { Class.new(described_class) { def prepare_registry; end } }
  let(:runner)    { ROM::Migrator::Runner }
  let(:generator) { ROM::Migrator::Generator }

  let(:migrator)  { klass.new gateway, folders: folders, logger: logger }
  let(:gateway)   { double :gateway, foo: :qux }
  let(:folders)   { ["db/migrate", "spec/dummy/db/migrate"] }
  let(:logger)    { double(:logger).as_null_object }

  describe ".default_path" do
    it "gets/sets custom path" do
      expect { klass.default_path "custom" }
        .to change { klass.default_path }
        .from("db/migrate")
        .to("custom")
    end
  end # describe .adapter

  describe ".template" do
    let(:default) { File.expand_path "rom/migrator/generator/template.erb" }

    it "gets/sets path to template" do
      expect { klass.template "custom" }
        .to change { klass.template }
        .from(default)
        .to("custom")
    end
  end # describe .adapter

  describe ".new" do
    before do
      klass.send(:define_method, :prepare_registry) { @registry = :ok }
    end

    it "prepares versions registry" do
      expect(migrator.instance_variable_get :@registry).to eql :ok
    end
  end # describe .new

  describe "#template" do
    subject { migrator.template }

    it "is set from class" do
      klass.template "custom"

      expect(subject).to eql "custom"
    end
  end # describe #template

  describe "#gateway" do
    subject { migrator.gateway }

    it { is_expected.to eql gateway }
  end # describe #gateway

  describe "#folders" do
    subject { migrator.folders }

    context "when list provided" do
      it { is_expected.to eql folders }
    end

    context "when string provided" do
      let(:migrator) { klass.new gateway, folders: "custom" }

      it { is_expected.to eql ["custom"] }
    end

    context "when not provided" do
      let(:migrator) { klass.new gateway }

      it "is set from class" do
        klass.default_path "custom"

        expect(subject).to eql ["custom"]
      end
    end
  end # describe #default_path

  describe "#logger" do
    subject { migrator.logger }

    it { is_expected.to eql logger }

    context "when not provided" do
      let(:logger) { nil }

      it "uses default logger" do
        expect(subject).to be_kind_of ROM::Migrator::Logger
      end
    end
  end # describe #logger

  describe "#next_migration_number" do
    subject { migrator.next_migration_number("1") }

    let(:time) { Time.utc(2017, 9, 10, 21, 30, 15.0394) }

    it "returns the current UTC timestamp accurate to milliseconds" do
      Timecop.freeze(time) do
        expect(subject).to eql "20170910213015039"
      end
    end
  end # describe #next_migration_number

  describe "#apply" do
    before  { allow(runner).to receive(:apply) }

    context "with options" do
      subject { migrator.apply options }

      let(:options) { { target: "109" } }

      it "works" do
        expect(runner).to receive(:apply).with(migrator, options)
        expect(subject).to eql migrator
      end
    end

    context "without options" do
      subject { migrator.apply }

      it "works" do
        expect(runner).to receive(:apply).with(migrator, {})
        expect(subject).to eql migrator
      end
    end
  end # describe #apply

  describe "#reverse" do
    before  { allow(runner).to receive(:reverse) }

    context "with options" do
      subject { migrator.reverse options }

      let(:options) { { target: "109" } }

      it "works" do
        expect(runner).to receive(:reverse).with(migrator, options)
        expect(subject).to eql migrator
      end
    end

    context "without options" do
      subject { migrator.reverse }

      it "works" do
        expect(runner).to receive(:reverse).with(migrator, {})
        expect(subject).to eql migrator
      end
    end
  end # describe #reverse

  describe "#generate" do
    subject { migrator.generate options }
    before  { allow(generator).to receive(:call) { "new_file.rb" } }

    context "with path" do
      let(:options) { { path: "custom", klass: "Foo::Bar", number: "3" } }

      it "builds and calls a generator" do
        expect(generator)
          .to receive(:call)
          .with(migrator, options)
        expect(subject).to eql "new_file.rb"
      end
    end

    context "without folders" do
      let(:options) { { klass: "Foo::Bar", number: "3" } }

      it "builds and calls a generator with the first folder" do
        expect(generator)
          .to receive(:call)
          .with(migrator, options.merge(path: "db/migrate"))
        expect(subject).to eql "new_file.rb"
      end
    end
  end # describe #generate

  describe "#migration" do
    subject { migrator.migration { up { :foo } } }

    it "provides custom migration" do
      expect(subject).to be_kind_of ROM::Migrator::Migration
      expect(subject.class.up.call).to eql :foo
    end

    it "uses current migrator" do
      expect(subject.migrator).to eql migrator
    end

    it "doesn't set the migration number" do
      expect(subject.number).to be_nil
    end
  end # describe #migration

  describe "#method_missing" do
    subject { migrator.foo :bar, :baz }

    it "forwards unknown methods to #gateway" do
      expect(gateway).to receive(:foo).with(:bar, :baz)
      expect(subject).to eql :qux
    end
  end # describe #method_missing

  describe "#respond_to_missing?" do
    subject { migrator.respond_to? name }

    context "method known to #gateway" do
      let(:name) { :foo }

      it { is_expected.to eql true }
    end

    context "method unknown to #gaeway" do
      let(:name) { :quxx }

      it { is_expected.to eql false }
    end
  end # describe #respond_to?

end # describe ROM::Migrator
