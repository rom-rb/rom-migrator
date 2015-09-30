# encoding: utf-8

describe ROM::Migrator::Generator::Binding do
  let(:binding) { described_class.new klass }
  let(:klass)   { "Foo::Bar" }
  let(:adapter) { :custom_adapter }

  describe ".new" do
    subject { binding }

    it { is_expected.to be_immutable }
  end # describe .new

  describe ".[]" do
    subject { described_class[klass] }

    it { is_expected.to be_kind_of ::Binding }

    it "carries @klass" do
      expect(eval("@klass", subject)).to eql klass
    end
  end # describe .[]

end # describe ROM::Migrator::Generator::Binding
