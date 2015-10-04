# encoding: utf-8

describe ROM::Migrator::Errors::MigrationNameError do
  let(:error) { described_class.new "foo" }

  describe ".new" do
    subject { error }

    it { is_expected.to be_kind_of ::NameError }
  end # describe .new

  describe "#message" do
    subject { error.message }

    it { is_expected.to eql "'foo' is not a valid migration" }
  end # describe #message

end # describe ROM::Migrator::Errors::MigrationNameError
