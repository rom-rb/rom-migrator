# encoding: utf-8

describe ROM::Migrator::Migration do
  let(:klass)     { Class.new(described_class) { define_method(:freeze) {} } }
  let(:migration) { klass.new(migrator: migrator, number: number) }
  let(:migrator)  { frozen_double :migrator, register: nil, unregister: nil }
  let(:number)    { "1" }

  describe ".new" do
    subject { described_class.new(migrator: migrator, number: number) }

    it { is_expected.to be_immutable }
  end # describe .new

  describe "#options" do
    subject { migration.options }

    it { is_expected.to eql(migrator: migrator, number: number.to_s) }
  end # describe #options

  describe "#migrator" do
    subject { migration.migrator }

    it { is_expected.to eql migrator }
  end # describe #migrator

  describe "#number" do
    subject { migration.number }

    it { is_expected.to eql number }
  end # describe #number

  describe "#up" do
    subject { migration.up }

    it { is_expected.to be_nil }
  end # describe #up

  describe "#down" do
    subject { migration.down }

    it { is_expected.to be_nil }
  end # describe #down

  describe "#apply" do
    subject { migration.apply }

    it "calls #up" do
      expect(migration).to receive(:up)
      subject
    end

    it "registers the number" do
      expect(migrator).to receive(:register).with(number)
      subject
    end

    context "when #up fails" do
      before { allow(migration).to receive(:up) { fail } }

      it "doesn't register number" do
        expect(migrator).not_to receive(:register)
        subject rescue nil
      end
    end
  end # describe #register

  describe "#rollback" do
    subject { migration.rollback }

    it "calls #down" do
      expect(migration).to receive(:down)
      subject
    end

    it "registers the number" do
      expect(migrator).to receive(:unregister).with(number)
      subject
    end

    context "when #down fails" do
      before { allow(migration).to receive(:down) { fail } }

      it "doesn't unregister number" do
        expect(migrator).not_to receive(:unregister)
        subject rescue nil
      end
    end
  end # describe #unregister

  describe "#method_missing" do
    subject { migration.foo(:bar) }

    it "forwards to #migrator" do
      allow(migrator).to receive(:foo) { :baz }

      expect(migrator).to receive(:foo).with(:bar)
      expect(subject).to eql :baz
    end
  end # describe #arbitrary_method

  describe "#respond_to?" do
    subject { migration.respond_to? :foo }

    context "method provided by #migrator" do
      before { allow(migrator).to receive(:foo) }

      it { is_expected.to eql true }
    end

    context "method not provided by #migrator" do
      it { is_expected.to eql false }
    end
  end # describe #respond_to?

end # describe ROM::Migrator::Migration
