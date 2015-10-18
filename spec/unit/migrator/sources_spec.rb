# encoding: utf-8
describe ROM::Migrator::Sources do

  let(:sources) { described_class.new [foo, bar, baz] }

  let(:foo) { frozen_double(number: "foo", to_migration: :migration_foo) }
  let(:bar) { frozen_double(number: "bar", to_migration: :migration_bar) }
  let(:baz) { frozen_double(number: "baz", to_migration: :migration_baz) }

  describe ".new" do
    subject { sources }

    it { is_expected.to be_immutable }
  end # describe .new

  describe "#each" do
    subject { sources.each }

    it { is_expected.to be_kind_of Enumerator }

    it "iterates through sources" do
      expect(subject.map(&:number)).to contain_exactly("bar", "baz", "foo")
    end
  end # describe #each

  describe "#with_numbers" do
    context "of existing sources" do
      subject { sources.with_numbers %w(bar baz) }

      it "selects sources by numbers" do
        expect(subject).to collect_sources_with_numbers %w(bar baz)
      end
    end

    context "of missed sources [strictly]" do
      subject { sources.with_numbers %w(bar baz qux) }

      it "fails" do
        expect { subject }
          .to raise_error ROM::Migrator::Errors::NotFoundError, /qux/
      end
    end

    context "of missed sources [not strictly]" do
      subject { sources.with_numbers %w(bar baz qux), false }

      it "selects sources by numbers" do
        expect(subject).to collect_sources_with_numbers %w(bar baz qux)
      end

      it "mocks missed sources" do
        missed_source = subject.to_a.last
        expect(missed_source.content).to eql "ROM::Migrator.migration"
      end
    end
  end # describe #with_numbers

  describe "#after_numbers" do
    context "empty" do
      subject { sources.after_numbers }

      it { is_expected.to eql sources }
    end

    context "one number" do
      subject { sources.after_numbers("bar") }

      it { is_expected.to collect_sources_with_numbers %w(baz foo) }
    end

    context "list of numbers" do
      subject { sources.after_numbers("bar", ["baz"], nil) }

      it { is_expected.to collect_sources_with_numbers %w(foo) }
    end

    context "absent number" do
      subject { sources.after_numbers("elf") }

      it { is_expected.to collect_sources_with_numbers %w(foo) }
    end
  end # describe #after_numbers

  describe "#upto_number" do
    context "with value" do
      subject { sources.upto_number("baz") }

      it { is_expected.to collect_sources_with_numbers %w(bar baz) }
    end

    context "without value" do
      subject { sources.upto_number }

      it { is_expected.to eql sources }
    end
  end # describe #after_numbers

  describe "#last_number" do
    subject { sources.last_number }

    it { is_expected.to eql "foo" }

    context "when sources are absent" do
      let(:sources) { described_class.new [] }

      it { is_expected.to eql "" }
    end
  end # describe #last_number

  describe "#to_migrations" do
    subject { sources.to_migrations(migrator) }
    let(:migrator) { double :migrator }

    it "converts all sources to migrations" do
      [foo, bar, baz].each do |source|
        expect(source).to receive(:to_migration).with(migrator).once
      end
      subject
    end

    it "returns the collection of migrations" do
      expect(subject).to be_kind_of ROM::Migrator::Migrations
      expect(subject.to_a)
        .to match_array [:migration_foo, :migration_bar, :migration_baz]
    end
  end # describe #to_migrations

  describe ".from_folders", :memfs do
    include_context :migrations
    subject { described_class.from_folders paths }

    it "creates the collection" do
      expect(subject).to be_kind_of described_class
    end

    it "populates the collection from files in given folders" do
      expect(subject.map(&:number)).to contain_exactly("1", "2", "3")
    end
  end # describe .from_folders

  RSpec::Matchers.define :collect_sources_with_numbers do |nums|
    match do |actual|
      expect(actual).to be_kind_of described_class
      expect(actual.map(&:number)).to match_array nums
    end
  end # matcher collect_sources_with_numbers

end # describe ROM::Migrator::Sources
