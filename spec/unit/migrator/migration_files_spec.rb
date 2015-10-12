# encoding: utf-8
describe ROM::Migrator::MigrationFiles do

  let(:files) { described_class.new foo, [bar, baz] }

  let(:foo) { frozen_double(number: "foo", to_migration: :migration_foo) }
  let(:bar) { frozen_double(number: "bar", to_migration: :migration_bar) }
  let(:baz) { frozen_double(number: "baz", to_migration: :migration_baz) }

  describe ".from", :memfs do
    include_context :migrations
    subject { described_class.from folders }

    it "creates the collection with all files in given folders" do
      expect(subject).to be_kind_of described_class
      expect(subject.map(&:number)).to contain_exactly("1", "2", "3")
    end
  end # describe .from

  describe ".new" do
    subject { files }

    it { is_expected.to be_immutable }
  end # describe .new

  describe "#each" do
    subject { files.each }

    it { is_expected.to be_kind_of Enumerator }

    it "iterates through files" do
      expect(subject.map(&:number)).to contain_exactly("bar", "baz", "foo")
    end
  end # describe #each

  describe "#with_numbers" do
    context "empty" do
      subject { files.with_numbers }

      it { is_expected.to collect_files_with_numbers %w() }
    end

    context "one number" do
      subject { files.with_numbers("baz") }

      it { is_expected.to collect_files_with_numbers %w(baz) }
    end

    context "list of numbers" do
      subject { files.with_numbers("baz", ["bar"], nil) }

      it { is_expected.to collect_files_with_numbers %w(bar baz) }
    end

    context "absent number" do
      subject { files.with_numbers("qux") }

      it "fails" do
        expect { subject }
          .to raise_error ROM::Migrator::Errors::NotFoundError, /qux/
      end
    end
  end # describe #with_numbers

  describe "#after_numbers" do
    context "empty" do
      subject { files.after_numbers }

      it { is_expected.to eql files }
    end

    context "one number" do
      subject { files.after_numbers("bar") }

      it { is_expected.to collect_files_with_numbers %w(baz foo) }
    end

    context "list of numbers" do
      subject { files.after_numbers("bar", ["baz"], nil) }

      it { is_expected.to collect_files_with_numbers %w(foo) }
    end

    context "absent number" do
      subject { files.after_numbers("elf") }

      it { is_expected.to collect_files_with_numbers %w(foo) }
    end
  end # describe #after_numbers

  describe "#upto_number" do
    context "with value" do
      subject { files.upto_number("baz") }

      it { is_expected.to collect_files_with_numbers %w(bar baz) }
    end

    context "without value" do
      subject { files.upto_number }

      it { is_expected.to eql files }
    end
  end # describe #after_numbers

  describe "#last_number" do
    subject { files.last_number }

    it { is_expected.to eql "foo" }

    context "when files are absent" do
      let(:files) { described_class.new }

      it { is_expected.to eql "" }
    end
  end # describe #last_number

  describe "#to_migrations" do
    subject { files.to_migrations(migrator) }
    let(:migrator) { double :migrator }

    it "converts all files to migrations" do
      [foo, bar, baz].each do |file|
        expect(file).to receive(:to_migration).with(migrator).once
      end
      subject
    end

    it "returns the collection of migrations" do
      expect(subject).to be_kind_of ROM::Migrator::Migrations
      expect(subject.to_a)
        .to match_array [:migration_foo, :migration_bar, :migration_baz]
    end
  end # describe #to_migrations

  RSpec::Matchers.define :collect_files_with_numbers do |nums|
    match do |actual|
      expect(actual).to be_kind_of described_class
      expect(actual.map(&:number)).to match_array nums
    end
  end # matcher collect_files_with_numbers

end # describe ROM::Migrator::MigrationFiles
