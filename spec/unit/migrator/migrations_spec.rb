# encoding: utf-8
describe ROM::Migrator::Migrations do

  let(:migrations) { described_class.new foo, [bar, baz] }

  let(:foo) { double :migration, number: "foo", apply: nil, reverse: nil }
  let(:bar) { double :migration, number: "bar", apply: nil, reverse: nil }
  let(:baz) { double :migration, number: "baz", apply: nil, reverse: nil }

  describe ".new" do
    subject { migrations }

    it { is_expected.to be_frozen }
    it { is_expected.not_to be_immutable }
  end # describe .new

  describe "#each" do
    subject { migrations.each }

    it { is_expected.to be_kind_of Enumerator }

    it "iterates via migrations" do
      expect(subject.to_a).to contain_exactly(foo, bar, baz)
    end
  end

  describe "#apply" do
    subject { migrations.apply }

    it "applies all migrations in ascending order" do
      expect(bar).to receive(:apply).ordered
      expect(baz).to receive(:apply).ordered
      expect(foo).to receive(:apply).ordered
      subject
    end

    it "returns itself" do
      expect(subject).to eql migrations
    end
  end # describe #apply

  describe "#reverse" do
    subject { migrations.reverse }

    it "reverses all migrations in descending order" do
      expect(foo).to receive(:reverse).ordered
      expect(baz).to receive(:reverse).ordered
      expect(bar).to receive(:reverse).ordered
      subject
    end

    it "returns itself" do
      expect(subject).to eql migrations
    end
  end # describe #reverse

end # describe ROM::Migrator::MigrationFiles
