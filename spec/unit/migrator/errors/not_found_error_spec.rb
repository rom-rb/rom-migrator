# encoding: utf-8

describe ROM::Migrator::Errors::NotFoundError do
  let(:error) { described_class.new "foo", "bar", "baz" }

  describe ".new" do
    subject { error }

    it { is_expected.to be_kind_of ::IOError }
  end # describe .new

  describe "#message" do
    subject { error.message }

    it do
      is_expected.to eql "migration number 'foo' wasn't found in folders:" \
                         "\n- 'bar'," \
                         "\n- 'baz'"
    end
  end # describe #message

end # describe ROM::Migrator::Errors::NotFoundError
