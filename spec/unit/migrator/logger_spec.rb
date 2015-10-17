# encoding: utf-8
describe ROM::Migrator::Logger do

  let(:logger) { described_class.new }
  let(:stdout) { StringIO.new }

  before { $stdout = stdout }
  after  { $stdout = STDOUT }

  describe ".new" do
    subject { logger }

    it { is_expected.to be_kind_of ::Logger }

    it { is_expected.not_to be_frozen }

    it "sends formatted messages to $stdout" do
      expect { subject.info "foo\nbar\nbaz" }
        .to change { stdout.string }
        .to "foo\n  bar\n  baz\n"
    end
  end # describe .new

end # describe ROM::Migrator::Logger
