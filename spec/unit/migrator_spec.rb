# encoding: utf-8

require "rom"
require "timecop"

describe ROM::Migrator do

  let(:klass)     { Class.new(described_class) { def prepare_registry; end } }
  let(:runner)    { ROM::Migrator::Runner }
  let(:generator) { ROM::Migrator::Generator }
  let(:migrator)  { klass.new gateway }
  let(:gateway)   { double :gateway }
  let(:folders)   { ["db/migrate", "spec/dummy/db/migrate"] }

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

  describe "#gateway" do
    subject { migrator.gateway }

    it { is_expected.to eql gateway }
  end # describe #gateway

  describe "#default_path" do
    subject { migrator.default_path }

    it "is set from class" do
      klass.default_path "custom"

      expect(subject).to eql "custom"
    end
  end # describe #default_path

  describe "#template" do
    subject { migrator.template }

    it "is set from class" do
      klass.template "custom"

      expect(subject).to eql "custom"
    end
  end # describe #template

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
    subject { migrator.apply options }
    before  { allow(runner).to receive(:apply) }

    let(:options) { { folders: folders, target: "109", logger: logger } }
    let(:logger)  { double :logger }

    it "applies runner" do
      expect(runner)
        .to receive(:apply)
        .with(options.merge(migrator: migrator))
      subject
    end

    it { is_expected.to eql migrator }

    context "without logger" do
      let(:options) { { folders: folders, target: "109" } }

      it "uses default logger" do
        expect(runner).to receive(:apply) do |options|
          expect(options[:logger]).to be_kind_of ROM::Migrator::Logger
        end
        subject
      end
    end
  end # describe #apply

  describe "#rollback" do
    subject { migrator.rollback options }
    before  { allow(runner).to receive(:rollback) }

    let(:options) { { folders: folders, target: "109", logger: logger } }
    let(:logger)  { double :logger }

    it "builds and rolls back runner" do
      expect(runner)
        .to receive(:rollback)
        .with(options.merge(migrator: migrator))
      subject
    end

    it "returns itself" do
      expect(subject).to eql migrator
    end

    context "without logger" do
      let(:options) { { folders: folders, target: "109" } }

      it "uses default logger" do
        expect(runner).to receive(:rollback) do |options|
          expect(options[:logger]).to be_kind_of ROM::Migrator::Logger
        end
        subject
      end
    end
  end # describe #rollback

  describe "#generate" do
    subject { migrator.generate options }
    before  { allow(generator).to receive(:call) }

    let(:options) { { folders: folders, klass: "Foo::Bar" } }

    it "builds and calls a generator" do
      expect(generator)
        .to receive(:call)
        .with(options.merge(migrator: migrator))
      subject
    end

    it "returns itself" do
      expect(subject).to eql migrator
    end
  end # describe #generate

end # describe ROM::Migrator
