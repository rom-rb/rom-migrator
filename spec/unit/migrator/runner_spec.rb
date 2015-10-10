# encoding: utf-8
describe ROM::Migrator::Runner do

  let(:runner)     { described_class.new options }
  let(:folders)    { ["db/migrate", "spec/dummy/db/migrate"] }
  let(:target)     { "2" }
  let(:registered) { [] }
  let(:logger)     { ::Logger.new(StringIO.new) }

  let(:migrator) do
    double(
      :migrator, go: nil, register: nil, unregister: nil, registered: registered
    )
  end

  let(:options) do
    { migrator: migrator, folders: folders, target: target, logger: logger }
  end

  describe ".new" do
    subject { runner }

    it { is_expected.to be_kind_of Enumerable }
  end # describe .new

  describe ".apply" do
    after { described_class.apply(options) }

    let(:runner) { double :runner, apply: nil }

    it "instantiates and applies the runner" do
      allow(described_class).to receive(:new) { runner }

      expect(described_class).to receive(:new).with options
      expect(runner).to receive(:apply)
    end
  end # describe .apply

  describe ".reverse" do
    after { described_class.reverse(options) }

    let(:runner) { double :runner, reverse: nil }

    it "instantiates the runner and reverses migrations" do
      allow(described_class).to receive(:new) { runner }

      expect(described_class).to receive(:new).with options
      expect(runner).to receive(:reverse)
    end
  end # describe .reverse

  describe "#options" do
    subject { runner.options }

    it { is_expected.to eql options }
  end # describe #options

  describe "#migrator" do
    subject { runner.migrator }

    it { is_expected.to eql migrator }
  end # describe #migrator

  describe "#folders" do
    subject { runner.folders }

    it { is_expected.to eql folders }
  end # describe #folders

  describe "#target" do
    subject { runner.target }

    it { is_expected.to eql target }
  end # describe #target

  describe "#logger" do
    subject { runner.logger }

    it { is_expected.to eql logger }
  end # describe #logger

  describe "#apply", :memfs do
    subject { runner.apply }
    include_context :migrations

    context "without target" do
      let(:target)     { nil }
      let(:registered) { ["1"] }

      it "applies all non-registered migrations" do
        expect(migrator).not_to receive(:go).with "CREATE TABLE users;"
        expect(migrator).to receive(:go).with("CREATE TABLE roles;").ordered
        expect(migrator).to receive(:go).with("CREATE TABLE accounts;").ordered
        subject
      end
    end

    context "with target" do
      let(:target)     { "2" }
      let(:registered) { [] }

      it "applies non-registered migrations up to the target" do
        expect(migrator).to receive(:go).with("CREATE TABLE users;").ordered
        expect(migrator).to receive(:go).with("CREATE TABLE roles;").ordered
        expect(migrator).not_to receive(:go).with("CREATE TABLE accounts;")
        subject
      end

      it "logs the results" do
        expect(logger).to receive(:info).twice
        subject
      end
    end
  end # describe #apply

  describe "#reverse", :memfs do
    subject { runner.reverse }
    include_context :migrations

    context "without target" do
      let(:target)     { nil }
      let(:registered) { %w(1 2) }

      it "reverses all registered migrations" do
        expect(migrator).not_to receive(:go).with "DROP TABLE accounts;"
        expect(migrator).to receive(:go).with("DROP TABLE roles;").ordered
        expect(migrator).to receive(:go).with("DROP TABLE users;").ordered
        subject
      end

      it "logs the results" do
        expect(logger).to receive(:info).twice
        subject
      end
    end

    context "with target" do
      let(:target)     { "1" }
      let(:registered) { %w(1 3) }

      it "reverses migrations, registered after the target" do
        expect(migrator).to receive(:go).with("DROP TABLE accounts;").ordered
        expect(migrator).not_to receive(:go).with("DROP TABLE roles;")
        expect(migrator).not_to receive(:go).with("DROP TABLE users;")
        subject
      end

      it "logs the results" do
        expect(logger).to receive(:info).once
        subject
      end
    end
  end # describe #reverse

end # describe ROM::Migrator::Runner
