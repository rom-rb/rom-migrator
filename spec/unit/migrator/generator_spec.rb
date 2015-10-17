# encoding: utf-8
describe ROM::Migrator::Generator do

  let(:generator) { described_class.new options }
  let(:options) do
    {
      path:     "/db/migrate/custom",
      name:     "CreateDalmatines",
      number:   "101",
      logger:   frozen_double(:logger, {}).as_null_object,
      template: "/config/custom_migration.txt"
    }
  end

  describe ".new" do
    subject { generator }

    it { is_expected.to be_kind_of described_class }
    it { is_expected.to be_immutable }
  end # describe .new

  describe "#path" do
    subject { generator.path }

    context "when absolute path is given" do
      it "returns the path" do
        expect(subject).to eql options[:path]
      end
    end

    context "when relative path is given" do
      before { options[:path] = "../db/migrate/custom" }

      it "returns the absolute path" do
        expect(subject).to eql File.expand_path(options[:path])
      end
    end
  end # describe #path

  describe "#template" do
    subject { generator.template }

    context "when absolute path is given" do
      it "returns the path" do
        expect(subject).to eql options[:template]
      end
    end

    context "when relative path is given" do
      before { options[:template] = "../config/custom_migration.txt" }

      it "returns the absolute path" do
        expect(subject).to eql File.expand_path(options[:template])
      end
    end
  end # describe #template

  describe "#target" do
    subject { generator.target }

    context "with a name" do
      it { is_expected.to eql "/db/migrate/custom/101_create_dalmatines.rb" }
    end

    context "without a name" do
      before { options.delete(:name) }

      it { is_expected.to eql "/db/migrate/custom/101.rb" }
    end

    context "from relative path" do
      before { options[:path] = "./db/migrate/custom" }

      it "returns absolute path" do
        expect(subject)
          .to eql File.join(generator.path, "101_create_dalmatines.rb")
      end
    end
  end # describe #target

  describe "#call", :memfs do
    subject { generator.call }

    context "in case of success" do
      include_context :custom_template

      it "creates target file" do
        subject
        expected_content = File.read(template)
        actual_content   = File.read(generator.target)

        expect(actual_content).to eql expected_content
      end

      it "logs the result" do
        expect(options[:logger])
          .to receive(:info)
          .with "New migration created at '#{generator.target}'"
        subject
      end

      it "returns path to the target" do
        expect(subject).to eql generator.target
      end
    end

    context "in case of error" do
      # expected template is absent

      it "doesn't create migration file" do
        subject rescue nil
        expect(File).not_to exist(generator.target)
      end

      it "logs an error" do
        expect(options[:logger]).to receive(:error) do |text|
          expect(text).to match(
            /^Error occured while creating file '#{generator.target}': No such/
          )
        end
        subject rescue nil
      end

      it "raises the exception" do
        expect { subject }.to raise_error StandardError
      end
    end
  end # describe #call

  describe ".call" do
    subject { described_class.call(options) }

    let(:generator) { double(:generator, call: :foo) }

    it "builds and calls the generator" do
      allow(described_class).to receive(:new) { generator }

      expect(described_class).to receive(:new).with(options)
      expect(generator).to receive(:call)
      expect(subject).to eql generator.call
    end
  end # describe .call

end # describe ROM::Migrator::Generator
