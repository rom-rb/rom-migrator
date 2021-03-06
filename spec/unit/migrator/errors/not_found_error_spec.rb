# encoding: utf-8

describe ROM::Migrator::Errors::NotFoundError do
  let(:error) { described_class.new "foo" }

  describe ".new" do
    subject { error }

    it { is_expected.to be_kind_of RuntimeError }
  end # describe .new

  describe "#message" do
    subject { error.message }

    it { is_expected.to eql "Cannot find a migration with number 'foo'" }
  end # describe #message

end # describe ROM::Migrator::Errors::NotFoundError
