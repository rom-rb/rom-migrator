# encoding: utf-8
describe ROM::Migrator::Runner do

  let(:runner)   { described_class.new migrator, target: target }
  let(:migrator) { double(paths: paths, logger: logger).as_null_object }
  let(:target)   { "2" }
  let(:paths)    { %w(/db/migrate /spec/dummy/db/migrate) }
  let(:logger)   { double(:logger).as_null_object }

  describe ".new" do
    subject { runner }

    it { is_expected.to be_kind_of Enumerable }
  end # describe .new

  describe ".apply" do
    after { described_class.apply(migrator, target: target) }

    let(:runner) { double(:runner).as_null_object }

    it "instantiates and applies the runner" do
      allow(described_class).to receive(:new) { runner }

      expect(described_class).to receive(:new).with(migrator, target: target)
      expect(runner).to receive(:apply)
    end
  end # describe .apply

  describe ".reverse" do
    after { described_class.reverse(migrator, target: target) }

    let(:runner) { double(:runner).as_null_object }

    it "instantiates and reverses the runner" do
      allow(described_class).to receive(:new) { runner }

      expect(described_class).to receive(:new).with(migrator, target: target)
      expect(runner).to receive(:reverse)
    end
  end # describe .reverse

  describe "#migrator" do
    subject { runner.migrator }

    it { is_expected.to eql migrator }
  end # describe #migrator

  describe "#target" do
    subject { runner.target }

    it { is_expected.to eql target }
  end # describe #target

  describe "#apply", :memfs do
    include_context :migrations
    before { allow(migrator).to receive(:registered) { registered } }

    after { runner.apply }

    context "without target" do
      let(:target)     { nil }
      let(:registered) { ["1"] }

      it "applies all non-registered migrations" do
        expect(migrator).not_to receive(:go).with "CREATE TABLE users;"
        expect(migrator).to receive(:go).with("CREATE TABLE roles;").ordered
        expect(migrator).to receive(:go).with("CREATE TABLE accounts;").ordered
      end

      it "logs the results" do
        expect(logger).to receive(:info).twice
      end
    end

    context "with target" do
      let(:target)     { "2" }
      let(:registered) { [] }

      it "applies non-registered migrations up to the target" do
        expect(migrator).to receive(:go).with("CREATE TABLE users;").ordered
        expect(migrator).to receive(:go).with("CREATE TABLE roles;").ordered
        expect(migrator).not_to receive(:go).with("CREATE TABLE accounts;")
      end

      it "logs the results" do
        expect(logger).to receive(:info).twice
      end
    end
  end # describe #apply

  describe "#reverse", :memfs do
    include_context :migrations
    before { allow(migrator).to receive(:registered) { registered } }

    after { runner.reverse }

    context "without target" do
      let(:target)     { nil }
      let(:registered) { %w(1 2) }

      it "reverses all registered migrations" do
        expect(migrator).not_to receive(:go).with "DROP TABLE accounts;"
        expect(migrator).to receive(:go).with("DROP TABLE roles;").ordered
        expect(migrator).to receive(:go).with("DROP TABLE users;").ordered
      end

      it "logs the results" do
        expect(logger).to receive(:info).twice
      end
    end

    context "with target" do
      let(:target)     { "1" }
      let(:registered) { %w(1 3) }

      it "reverses migrations, registered after the target" do
        expect(migrator).to receive(:go).with("DROP TABLE accounts;").ordered
        expect(migrator).not_to receive(:go).with("DROP TABLE roles;")
        expect(migrator).not_to receive(:go).with("DROP TABLE users;")
      end

      it "logs the results" do
        expect(logger).to receive(:info).once
      end
    end
  end # describe #reverse

end # describe ROM::Migrator::Runner
