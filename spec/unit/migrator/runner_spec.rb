# # encoding: utf-8

describe ROM::Migrator::Runner do

  let(:runner)     { described_class.new options }
  let(:options)    { { migrator: migrator, folders: folders, target: target } }
  let(:folders)    { ["db/migrate", "spec/dummy/db/migrate"] }
  let(:target)     { "2" }
  let(:registered) { [] }
  let(:migrator) do
    frozen_double(
      :migrator, go: nil, register: nil, unregister: nil, registered: registered
    )
  end

  describe ".new" do
    subject { runner }

    it { is_expected.to be_kind_of Enumerable }
    it { is_expected.to be_immutable }
  end # describe .new

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

  describe "#files", :memfs do
    subject { runner.files }

    include_context :migrations

    it "returns files collection" do
      expect(subject).to be_kind_of ROM::Migrator::MigrationFiles
      expect(subject.map(&:number)).to eql %w(1 2 3)
    end
  end # describe #files

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
    end
  end # describe #apply

  describe "#rollback", :memfs do
    subject { runner.rollback }
    include_context :migrations

    context "without target" do
      let(:target)     { nil }
      let(:registered) { %w(1 2) }

      it "rolls back all registered migrations" do
        expect(migrator).not_to receive(:go).with "DROP TABLE accounts;"
        expect(migrator).to receive(:go).with("DROP TABLE roles;").ordered
        expect(migrator).to receive(:go).with("DROP TABLE users;").ordered
        subject
      end
    end

    context "with target" do
      let(:target)     { "1" }
      let(:registered) { %w(1 3) }

      it "rolls back migrations, registered after the target" do
        expect(migrator).to receive(:go).with("DROP TABLE accounts;").ordered
        expect(migrator).not_to receive(:go).with("DROP TABLE roles;")
        expect(migrator).not_to receive(:go).with("DROP TABLE users;")
        subject
      end
    end
  end # describe #rollback

end # describe ROM::Migrator::Runner
