# encoding: utf-8

describe ROM::Migrator::Errors::AlreadyReversedError do
  let(:error) { described_class.new "foo" }

  describe ".new" do
    subject { error }

    it { is_expected.to be_kind_of RuntimeError }
  end # describe .new

  describe "#message" do
    subject { error.message }

    it { is_expected.to include "migration with number 'foo'" }
    it { is_expected.to include "hasn't been applied yet" }
    it { is_expected.to include "has already been reversed" }
  end # describe #message

end # describe ROM::Migrator::Errors::AlreadyReversedError
