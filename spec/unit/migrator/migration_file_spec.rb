# encoding: utf-8
describe ROM::Migrator::MigrationFile do

  let(:file) { described_class.new path }
  let(:path) { double to_s: "foo/bar.rb" }

  describe ".new" do
    subject { file }

    it { is_expected.to be_kind_of described_class }
    it { is_expected.to be_immutable }
  end # describe .new

  describe "#number" do
    subject { file.number }

    context "from long name" do
      let(:path) { "foo/bar_baz_qux.rb" }

      it { is_expected.to eql "bar" }
    end

    context "from short name" do
      let(:path) { "foo/bar.rb" }

      it { is_expected.to eql "bar" }
    end
  end # describe #number

  describe "#valid?", :memfs do
    include_context :migrations
    subject { file.valid? }

    context "with valid migration" do
      let(:path) { "/db/migrate/1_create_users.rb" }

      it { is_expected.to eql true }
    end

    context "with migration w/o number" do
      let(:path) { "/db/migrate/_unnumbered.rb" }

      it { is_expected.to eql false }
    end

    context "when a file doesn't define a migration" do
      let(:path) { "/db/migrate/4_not_a_migration.rb" }

      it { is_expected.to eql false }
    end

    context "when a file is absent" do
      let(:path) { "/db/migrate/6_absent.rb" }

      it { is_expected.to eql false }
    end
  end # describe #valid?

  describe "#to_migration", :memfs do
    include_context :migrations
    let(:path) { "/db/migrate/1_create_users.rb" }

    subject { file.to_migration options }
    let(:options) { { gateway: double, logger: double, registrar: double } }

    it "builds the migration" do
      expect(subject).to be_kind_of ROM::Migrator::Migration
      expect(subject.options).to eql options.merge(number: "1")
    end

    context "when a file cannot be loaded" do
      let(:path) { "/db/migrate/4_not_a_migration.rb" }

      it "fails" do
        expect { subject }.to raise_error(
          ROM::Migrator::Errors::ContentError,
          /4_not_a_migration(.|\n)+undefined method/
        )
      end
    end

    context "when a file loads not a class" do
      let(:path) { "/db/migrate/5_symbol.rb" }

      it "fails" do
        expect { subject }.to raise_error(
          ROM::Migrator::Errors::ContentError,
          /5_symbol(.|\n)+ :foo/
        )
      end
    end

    context "when a file loads non-migration class" do
      let(:path) { "/db/migrate/6_symbol_class.rb" }

      it "fails" do
        expect { subject }.to raise_error(
          ROM::Migrator::Errors::ContentError,
          /6_symbol_class(.|\n)+ Symbol/
        )
      end
    end
  end # describe #to_migration

end # describe ROM::Migrator::MigrationFile
