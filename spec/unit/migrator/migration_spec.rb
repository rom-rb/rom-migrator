# encoding: utf-8
describe ROM::Migrator::Migration do

  let(:klass)     { Class.new(described_class) }
  let(:block)     { proc { go :foo } }

  let(:migration) { klass.new(options) }
  let(:options)   { { migrator: migrator, logger: logger, number: number } }
  let(:migrator)  { double :migrator, go: :BAZ, register: nil, unregister: nil }
  let(:logger)    { ::Logger.new(StringIO.new) }
  let(:number)    { "foo" }

  describe ".up" do
    subject { klass.up(&block) }

    it "gets or sets the proc" do
      expect { subject }.to change { klass.up }.from(nil).to(block)
    end
  end # describe .up

  describe ".down" do
    subject { klass.down(&block) }

    it "gets or sets the proc" do
      expect { subject }.to change { klass.down }.from(nil).to(block)
    end
  end # describe .down

  describe ".new" do
    subject { klass.new migrator: migrator }

    it { is_expected.to be_frozen }
    it { is_expected.not_to be_immutable }
  end # describe .new

  describe "#number" do
    subject { migration.number }

    it { is_expected.to eql number }

    context "when not provided" do
      let(:options) { { migrator: migrator } }

      it { is_expected.to be_nil }
    end
  end # describe #number

  describe "#logger" do
    subject { migration.logger }

    it { is_expected.to eql logger }

    context "when not provided" do
      let(:options) { { migrator: migrator } }

      it { is_expected.to be_kind_of ROM::Migrator::Logger }
    end

    context "when set to nil" do
      let(:logger) { nil }

      it { is_expected.to be_kind_of ROM::Migrator::Logger }
    end
  end # describe #logger

  describe "#apply" do
    before  { klass.up(&block) }
    subject { migration.apply }

    it "evaluates .up in the migrator's scope" do
      expect(migrator).to receive(:go).with :foo
      subject
    end

    it "registers the number" do
      expect(migrator).to receive(:register).with(number).once
      subject
    end

    it "logs the result" do
      expect(logger)
        .to receive(:info)
        .with "The migration number 'foo' has been applied"
      subject
    end

    it "returns itself" do
      expect(subject).to eql migration
    end

    context "when number isn't set" do
      let(:number) { nil }

      it "doesn't register a number" do
        expect(migrator).not_to receive(:register)
        subject
      end

      it "logs the result w/o number" do
        expect(logger)
          .to receive(:info)
          .with "The migration has been applied"
        subject
      end
    end

    context "in case of error" do
      let(:block) { proc { fail RuntimeError.new "something went wrong" } }

      it "doesn't register the number" do
        expect(migrator).not_to receive(:register)
        subject rescue nil
      end

      it "logs the error" do
        expect(logger)
          .to receive(:error)
          .with "The error occured when migration number 'foo' was applied:" \
                "\nsomething went wrong"
        subject rescue nil
      end

      it "re-raises the error" do
        expect { subject }.to raise_error RuntimeError, /something went wrong/
      end
    end
  end # describe #apply

  describe "#reverse" do
    before  { klass.down(&block) }
    subject { migration.reverse }

    it "evaluates .down in the migrator's scope" do
      expect(migrator).to receive(:go).with :foo
      subject
    end

    it "unregisters the number" do
      expect(migrator).to receive(:unregister).with(number).once
      subject
    end

    it "logs the result" do
      expect(logger)
        .to receive(:info)
        .with "The migration number 'foo' has been reversed"
      subject
    end

    it "returns itself" do
      expect(subject).to eql migration
    end

    context "when number isn't set" do
      let(:number) { nil }

      it "doesn't unregister a number" do
        expect(migrator).not_to receive(:unregister)
        subject
      end

      it "logs the result w/o number" do
        expect(logger)
          .to receive(:info)
          .with "The migration has been reversed"
        subject
      end
    end

    context "in case of error" do
      let(:block) { proc { fail RuntimeError.new "something went wrong" } }

      it "doesn't unregister the number" do
        expect(migrator).not_to receive(:unregister)
        subject rescue nil
      end

      it "logs the error" do
        expect(logger)
          .to receive(:error)
          .with "The error occured when migration number 'foo' was reversed:" \
                "\nsomething went wrong"
        subject rescue nil
      end

      it "re-raises the error" do
        expect { subject }.to raise_error RuntimeError, /something went wrong/
      end
    end
  end # describe #reverse

  describe "#method_missing" do
    subject { migration.go(:bar) }

    it "forwards to #migrator" do
      expect(migrator).to receive(:go).with(:bar)
      expect(subject).to eql :BAZ
    end
  end # describe #arbitrary_method

  describe "#respond_to?" do
    subject { migration.respond_to? method }

    context "method provided by #migrator" do
      let(:method) { :go }

      it { is_expected.to eql true }
    end

    context "method not provided by #migrator" do
      let(:method) { :foo }

      it { is_expected.to eql false }
    end
  end # describe #respond_to?

end # describe ROM::Migrator::Migration
