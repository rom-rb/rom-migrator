# encoding: utf-8
describe ROM::Migrator::Migration do

  let(:klass)     { Class.new(described_class) }
  let(:block)     { proc { go :foo } }
  let(:migration) { klass.new(options) }

  let(:options) do
    { gateway: gateway, registrar: registrar, logger: logger, number: number }
  end
  let(:gateway)   { double(:gateway).as_null_object }
  let(:registrar) { double(:registrar).as_null_object }
  let(:logger)    { double(:logger).as_null_object }
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

  describe "#to_s" do
    subject { migration.to_s }

    context "with number" do
      it { is_expected.to eql "migration number 'foo'" }
    end

    context "without number" do
      let(:number) { nil }

      it { is_expected.to eql "migration" }
    end
  end # describe #to_s

  describe "#apply" do
    before  { allow(registrar).to receive(:apply).and_yield }
    before  { klass.up(&block) }
    subject { migration.apply }

    it "unregisters the number" do
      expect(registrar).to receive(:apply).with(number)
      subject
    end

    it "evaluates .up in the gateway's scope" do
      expect(gateway).to receive(:go).with :foo
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

    context "when registrar fails" do
      before { allow(registrar).to receive(:apply) { fail } }

      it "doesn't evaluate .up" do
        expect(gateway).not_to receive(:go)
        subject rescue nil
      end

      it "logs the error" do
        expect(logger).to receive(:error)
        subject rescue nil
      end

      it "raises the error" do
        expect { subject }.to raise_error RuntimeError
      end
    end

    context "when gateway fails" do
      before { allow(gateway).to receive(:go) { fail "something went wrong" } }

      it "logs the error" do
        expect(logger)
          .to receive(:error)
          .with "The error occured when migration number 'foo' was applied:" \
                " something went wrong"
        subject rescue nil
      end

      it "re-raises the error" do
        expect { subject }.to raise_error RuntimeError, /something went wrong/
      end
    end
  end # describe #apply

  describe "#reverse" do
    before  { allow(registrar).to receive(:reverse).and_yield }
    before  { klass.down(&block) }
    subject { migration.reverse }

    it "unregisters the number" do
      expect(registrar).to receive(:reverse).with(number)
      subject
    end

    it "evaluates .down in the gateway's scope" do
      expect(gateway).to receive(:go).with :foo
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

    context "when registrar fails" do
      before { allow(registrar).to receive(:reverse) { fail } }

      it "doesn't evaluate .down" do
        expect(gateway).not_to receive(:go)
        subject rescue nil
      end

      it "logs the error" do
        expect(logger).to receive(:error)
        subject rescue nil
      end

      it "raises the error" do
        expect { subject }.to raise_error RuntimeError
      end
    end

    context "when gateway fails" do
      before { allow(gateway).to receive(:go) { fail "something went wrong" } }

      it "logs the error" do
        expect(logger)
          .to receive(:error)
          .with "The error occured when migration number 'foo' was reversed:" \
                " something went wrong"
        subject rescue nil
      end

      it "re-raises the error" do
        expect { subject }.to raise_error RuntimeError, /something went wrong/
      end
    end
  end # describe #reverse

end # describe ROM::Migrator::Migration
