# encoding: utf-8
describe ROM::Migrator::MigrationFile do

  let(:klass)      { Class.new(described_class) }
  let(:name_error) { described_class::MigrationNameError }

  let(:fn) { klass.new root: "/foo", path: "/foo/bar_baz/n_baz_qux.rb" }
  let(:kn) { klass.new root: "/foo", klass: "BarBaz::BazQux", number: "n" }

  describe ".new" do
    context "with valid arguments" do
      subject { fn }

      it { is_expected.to be_kind_of described_class }
      it { is_expected.to be_immutable }
    end

    context "with wrong filename" do
      subject { klass.new root: "/foo", path: "/foo/baz-qux.rb" }

      it "fails" do
        expect { subject }.to raise_error do |error|
          expect(error).to be_a name_error
          expect(error.message).to include "baz-qux.rb"
        end
      end
    end

    context "with wrong name" do
      subject { klass.new root: "/foo", klass: "", number: "n" }

      it "fails" do
        expect { subject }.to raise_error do |error|
          expect(error).to be_a name_error
          expect(error.message).to include "n_.rb"
        end
      end
    end

    context "with wrong number" do
      subject { klass.new root: "/foo", klass: "Foo::Bar", number: "" }

      it "fails" do
        expect { subject }.to raise_error do |error|
          expect(error).to be_a name_error
          expect(error.message).to include "/foo/_bar.rb"
        end
      end
    end

    context "without number" do
      subject { klass.new root: "/foo", klass: "Foo::Bar" }

      it "fails" do
        expect { subject }.to raise_error do |error|
          expect(error).to be_a name_error
          expect(error.message).to include "/foo/_bar.rb"
        end
      end
    end
  end # describe .new

  describe "#root" do
    subject { fn.root }

    it { is_expected.to eql "/foo" }
  end # describe #root

  describe "#number" do
    subject { file.number }

    context "from filename" do
      let(:file) { fn }

      it { is_expected.to eql "n" }
    end

    context "from klass and number" do
      let(:file) { kn }

      it { is_expected.to eql "n" }
    end
  end # describe #number

  describe "#klass" do
    subject { file.klass }

    context "from filename" do
      let(:file) { fn }

      it { is_expected.to eql "BarBaz::BazQux" }
    end

    context "from klass and number" do
      let(:file) { kn }

      it { is_expected.to eql "BarBaz::BazQux" }
    end
  end # describe #klass

  describe "#path" do
    subject { file.path }

    context "from filename" do
      let(:file) { fn }

      it { is_expected.to eql "/foo/bar_baz/n_baz_qux.rb" }
    end

    context "from klass and number" do
      let(:file) { kn }

      it { is_expected.to eql "/foo/bar_baz/n_baz_qux.rb" }
    end
  end # describe #path

  describe "#to_migration", :memfs do
    include_context :migrations
    subject { file.to_migration migrator: migrator, logger: logger }

    let(:migrator) { double :migrator }
    let(:logger)   { double :logger }
    let(:file) do
      klass.new root: "/db/migrate", path: "/db/migrate/1_create_users.rb"
    end

    it "builds the migration" do
      expect(subject).to be_kind_of   CreateUsers
      expect(subject.number).to eql   "1"
      expect(subject.migrator).to eql migrator
      expect(subject.logger).to eql   logger
    end

    after { Object.send :remove_const, :CreateUsers }

  end # describe #to_migration

end # describe ROM::Migrator::MigrationFile
