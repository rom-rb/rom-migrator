# encoding: utf-8

describe ROM::Migrator::Registrar do

  let(:klass)     { Class.new(described_class) }
  let(:registrar) { klass.new(gateway) }
  let(:gateway)   { frozen_double(:gateway, foo: :bar) }

  describe "#prepare_registry" do
    subject { registrar.prepare_registry }

    it { is_expected.to be_nil }
  end # describe #prepare_registry

  describe "#registered" do
    subject { registrar.registered }

    it { is_expected.to eql [] }
  end # describe #registered

  describe "#registered?" do
    subject { registrar.registered? :qux }

    context "when a number isn't registered" do
      it { is_expected.to eql false }
    end

    context "when a number is registered" do
      before { allow(registrar).to receive(:registered) { [:qux] } }

      it { is_expected.to eql true }
    end
  end # describe #registered?

  describe "#register" do
    subject { registrar.register :qux }

    it { is_expected.to be_nil }
  end # describe #register

  describe "#unregister" do
    subject { registrar.unregister :qux }

    it { is_expected.to be_nil }
  end # describe #unregister

  describe "#method_missing" do
    subject { registrar.foo :baz }

    it "delegates all methods to gateway" do
      expect(gateway).to receive(:foo).with(:baz)
      expect(subject).to eql :bar
    end
  end # describe #method_missing

  describe ".new" do
    subject { registrar }

    it "authomatically prepares the registry" do
      klass.send(:define_method, :prepare_registry) { foo :baz, :qux }

      expect(gateway).to receive(:foo).with(:baz, :qux)
      subject
    end
  end # describe .new

  describe "#apply" do
    let!(:result) { [] }
    subject { registrar.apply(number) { result << :yielded } }

    context "unregistered number" do
      before { allow(registrar).to receive(:registered?) { |n| n != number } }
      let(:number) { "foo" }

      it "yields" do
        subject
        expect(result).to contain_exactly :yielded
      end

      it "registers number" do
        expect(registrar).to receive(:register).with(number)
        subject
      end
    end

    context "registered number" do
      before { allow(registrar).to receive(:registered?) { |n| n == number } }
      let(:number) { "foo" }

      it "fails" do
        expect { subject }
          .to raise_error ROM::Migrator::Errors::AlreadyAppliedError, /foo/
      end

      it "doesn't yield" do
        subject rescue nil
        expect(result).to be_empty
      end

      it "doesn't register number" do
        expect(registrar).not_to receive(:register)
        subject rescue nil
      end
    end

    context "empty number" do
      let(:number) { nil }

      it "yields" do
        subject
        expect(result).to contain_exactly :yielded
      end

      it "doesn't register number" do
        expect(registrar).not_to receive(:register)
        subject
      end
    end
  end # describe #apply

  describe "#reverse" do
    let!(:result) { [] }
    subject { registrar.reverse(number) { result << :yielded } }

    context "registered number" do
      before { allow(registrar).to receive(:registered?) { |n| n == number } }
      let(:number) { "foo" }

      it "yields" do
        subject
        expect(result).to contain_exactly :yielded
      end

      it "unregisters number" do
        expect(registrar).to receive(:unregister).with(number)
        subject
      end
    end

    context "unregistered number" do
      before { allow(registrar).to receive(:registered?) { |n| n != number } }
      let(:number) { "foo" }

      it "fails" do
        expect { subject }
          .to raise_error ROM::Migrator::Errors::AlreadyReversedError, /foo/
      end

      it "doesn't yield" do
        subject rescue nil
        expect(result).to be_empty
      end

      it "doesn't unregister number" do
        expect(registrar).not_to receive(:unregister)
        subject rescue nil
      end
    end

    context "empty number" do
      let(:number) { nil }

      it "yields" do
        subject
        expect(result).to contain_exactly :yielded
      end

      it "doesn't unregister number" do
        expect(registrar).not_to receive(:unregister)
        subject
      end
    end
  end # describe #reverse

  describe "#respond_to?" do
    it "uses a gateway" do
      expect(registrar).to respond_to :foo
      expect(registrar).not_to respond_to :bar
    end
  end # describe #respond_to?

end # describe ROM::Migrator::Registrar
