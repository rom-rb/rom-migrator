# encoding: utf-8

describe ROM::Migrator::Settings do

  let(:settings) { described_class.new }

  describe "#template" do
    subject { settings.template }

    it { is_expected.to eql File.join(ROOT, "lib/rom/migrator/template.txt") }
  end # describe #template

  describe "#path" do
    subject { settings.path }

    it { is_expected.to eql "db/migrate" }
  end # describe #path

  describe "#logger" do
    subject { settings.logger }

    it { is_expected.to be_kind_of ROM::Migrator::Logger }
  end # describe #logger

  describe "#counter" do
    subject { settings.counter[1] }

    it "returns 17-digit timestamp" do
      time = Time.utc(2017, 1, 3, 19, 7, 32.9321)
      Timecop.freeze(time) { expect(subject).to eql "20170103190732932" }
    end
  end # describe #counter

  describe "#default_template" do
    subject { settings.default_template template }

    let(:template) { "foo/bar" }

    it "returns new settings with updated #template" do
      expect(subject).to be_kind_of described_class
      expect(subject).not_to eql settings
      expect(subject.template).to eql "foo/bar"
    end
  end # describe #default_template

  describe "#default_path" do
    subject { settings.default_path path }

    let(:path) { "foo/bar" }

    it "returns new settings with updated #path" do
      expect(subject).to be_kind_of described_class
      expect(subject).not_to eql settings
      expect(subject.path).to eql "foo/bar"
    end
  end # describe #default_path

  describe "#default_logger" do
    subject { settings.default_logger logger }

    let(:logger) { ::Logger.new(StringIO.new) }

    it "returns new settings with updated #logger" do
      expect(subject).to be_kind_of described_class
      expect(subject).not_to eql settings
      expect(subject.logger).to eql logger
    end
  end # describe #default_logger

  describe "#default_counter" do
    subject { settings.default_counter(&fn) }

    let(:fn) { -> old { old.to_i + 1 } }

    it "returns new settings with updated #counter" do
      expect(subject).to be_kind_of described_class
      expect(subject).not_to eql settings
      expect(subject.counter[1]).to eql 2
    end
  end # describe #default_counter

end # describe ROM::Migrator::Settings
