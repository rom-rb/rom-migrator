# # encoding: utf-8

describe ROM::Migrator::Generator do

  let(:generator) { described_class.new options }
  let(:options)   { { migrator: migrator, folders: folders, klass: klass } }
  let(:folders)   { ["/db/migrate", "/spec/dummy/db/migrate"] }
  let(:klass)     { "users/create_user" }

  let(:migrator) do # mock the migrator with a number counter
    object = double :migrator, template: "/config/custom_migration.erb"
    allow(object).to receive(:next_migration_number) { |i| "#{i.to_i + 1}m" }
    object
  end

  describe ".call" do
    let(:generator) { double :generator, call: nil }

    before { allow(described_class).to receive(:new) { generator } }
    after  { described_class.call options }

    it "builds and calls the generator" do
      expect(described_class).to receive(:new).with(options)
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

  describe "#options" do
    subject { generator.options }

    it { is_expected.to eql options }
  end # describe #options

  describe "#number", :memfs do
    subject { generator.number }

    context "when set explicitly" do
      before { options.update(number: 7) }

      it "is taken from options" do
        expect(subject).to eql "7"
      end
    end

    context "if no migrations exist" do
      it "is the first number" do
        expect(subject).to eql "1m"
      end
    end

    context "if migrations exist" do
      include_context :migrations

      it "is the next number" do
        expect(subject).to eql "4m"
      end
    end
  end # describe #number

  describe "#migrator" do
    subject { generator.migrator }

    it { is_expected.to eql migrator }
  end # describe #migrator

  describe "#folders" do
    subject { generator.folders }

    it { is_expected.to eql folders }
  end # describe #folders

  describe "#klass" do
    subject { generator.klass }

    it { is_expected.to eql "Users::CreateUser" }
  end # describe #klass

  describe "#call", :memfs do
    subject { generator.call }

    include_context :custom_template

    context "if no migrations exist" do
      it "generates first migration" do
        subject
        content = File.read "db/migrate/users/1m_create_user.rb"
        expect(content)
          .to include "class Users::CreateUser < ROM::Migrator::Migration"
      end
    end

    context "if migrations exist" do
      include_context :migrations

      it "generates next migration" do
        subject
        content = File.read "db/migrate/users/4m_create_user.rb"
        expect(content)
          .to include "class Users::CreateUser < ROM::Migrator::Migration"
      end
    end
  end # describe #call

end # describe ROM::Migrator::Generator
