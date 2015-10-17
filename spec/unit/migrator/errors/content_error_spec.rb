# encoding: utf-8

describe ROM::Migrator::Errors::ContentError do
  let(:error) { described_class.new "foo/bar", :foo }

  describe ".new" do
    subject { error }

    it { is_expected.to be_kind_of RuntimeError }
  end # describe .new

  describe "#message" do
    subject { error.message }

    it { is_expected.to include "File 'foo/bar'" }
    it { is_expected.to include "doesn't define a migration properly" }
    it { is_expected.to include ":foo" }
  end # describe #message

end # describe ROM::Migrator::Errors::ContentError
