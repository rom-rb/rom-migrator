# encoding: utf-8
describe ROM::Migrator::Generator do

  let(:generator) { described_class.new migrator, options }
  let(:migrator)  { double(:migrator).as_null_object }
  let(:options)   { { path: path, klass: klass, number: number } }

  let(:path)      { "/db/migrate/custom" }
  let(:klass)     { "cats/create_table" }
  let(:number)    { nil }

  describe ".call" do
    let(:generator) { double :generator, call: nil }

    before { allow(described_class).to receive(:new) { generator } }
    after  { described_class.call migrator, options }

    it "builds and calls the generator" do
      expect(described_class).to receive(:new).with(migrator, options)
      expect(generator).to receive(:call)
    end
  end # describe .call

  describe ".new" do
    subject { generator }

    context "with a klass name" do
      it { is_expected.to be_kind_of described_class }
    end

    context "without klass name" do
      let(:klass) { nil }

      it "fails" do
        expect { subject }.to raise_error ROM::Options::InvalidOptionValueError
      end
    end
  end # describe .new

  describe "#path" do
    subject { generator.path }

    it { is_expected.to eql path }
  end # path

  describe "#klass" do
    subject { generator.klass }

    it { is_expected.to eql "Cats::CreateTable" }
  end # describe #klass

  describe "#number" do
    subject { generator.number }

    it { is_expected.to be_nil }

    context "when set explicitly" do
      let(:number) { "1" }

      it { is_expected.to eql number }
    end
  end # describe #number

  describe "#migrator" do
    subject { generator.migrator }

    it { is_expected.to eql migrator }
  end # describe #migrator

  describe "#call", :memfs do
    subject { generator.call }

    shared_examples :adding_migration_with_number do |num|
      include_context :custom_template do
        let(:folders)  { %w(/db/migrate /spec/dummy/db/migrate) }
        let(:new_path) { "/db/migrate/custom/cats/#{num}_create_table.rb" }
        let(:content)  { "class Cats::CreateTable < ROM::Migrator::Migration" }
      end

      before do
        allow(migrator).to receive(:next_migration_number, &numerator)
        allow(migrator).to receive(:folders) { folders }
        allow(migrator).to receive(:template) { template }
        allow(migrator).to receive(:logger) { logger }
      end

      let(:numerator) { proc { |i| "#{i.to_i + 1}m" } }
      let(:logger)    { double(:logger).as_null_object }

      it "generates first migration" do
        subject
        expect(File).to be_exist new_path
        expect(File.read(new_path)).to include content
      end

      it "logs result" do
        expect(logger)
          .to receive(:info)
          .with "New migration created at '#{new_path}'"
        subject
      end

      it "returns path to migration" do
        expect(subject).to eql new_path
      end
    end

    it_behaves_like :adding_migration_with_number, "1m"

    it_behaves_like :adding_migration_with_number, "4m" do
      include_context :migrations
    end

    it_behaves_like :adding_migration_with_number, "5m" do
      let(:number) { "5m" }
    end
  end # describe #call

end # describe ROM::Migrator::Generator
