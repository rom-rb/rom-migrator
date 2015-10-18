# encoding: utf-8
describe ROM::Migrator::MigrationFile do

  let(:source)  { described_class.new options }
  let(:options) { { number: number, content: content } }
  let(:number)  { :"12" }
  let(:content) { "ROM::Migrator.migration { up { :foo } }" }

  describe ".new" do
    subject { source }

    it { is_expected.to be_immutable }
  end # describe .new

  describe ".from_file", :memfs do
    include_context :migrations
    subject { described_class.from_file(path) }

    context "when file is present" do
      let(:path) { "/db/migrate/1_create_users.rb" }

      it "instantiates a source" do
        expect(subject).to be_kind_of described_class
      end

      it "takes number from path" do
        expect(subject.number).to eql "1"
      end

      it "takes content from file" do
        expect(subject.content).to eql File.read(path)
      end
    end

    context "when file is absent" do
      let(:path) { "/db/migrate/0.rb" }

      it "fails" do
        expect { subject }
          .to raise_error ROM::Migrator::Errors::NotFoundError, /'0'/
      end
    end
  end # describe .from_file

  describe "#number" do
    subject { source.number }

    it { is_expected.to eql number.to_s }
  end # describe #number

  describe "#content" do
    subject { source.content }

    it { is_expected.to eql content }

    context "by default" do
      before { options.delete :content }

      it { is_expected.to eql "ROM::Migrator.migration" }
    end
  end # describe #content

  describe "#valid?" do
    subject { source.valid? }

    context "with valid number and anonymous migration" do
      let(:content) { "ROM::Migrator.migration" }

      it { is_expected.to eql true }
    end

    context "with valid number and subclassed migration" do
      let(:content) { "ROM::SQL::Migrator.migration" }

      it { is_expected.to eql true }
    end

    context "with valid number and subclassed migration" do
      let(:content) { "class Foo < ROM::Migrator::Migration" }

      it { is_expected.to eql true }
    end

    context "with valid number and subclassed migration" do
      let(:content) { "Foo = Class.new(ROM::Migrator::Migration)" }

      it { is_expected.to eql true }
    end

    context "with invalid content" do
      let(:content) { "class Foo" }

      it { is_expected.to eql false }
    end

    context "with empty number" do
      let(:number) { "" }

      it { is_expected.to eql false }
    end
  end # describe #valid?

  describe "#to_migration" do
    subject { source.to_migration(args) }
    let(:args) { { gateway: double, logger: double, registrar: double } }

    it "builds custom migration" do
      expect(subject).to be_kind_of ROM::Migrator::Migration
      expect(subject.options).to eql args.merge(number: number.to_s)
      expect(subject.class.up.call).to eql :foo
    end

    shared_examples :raising_content_error do
      it "[fails]" do
        expect { subject }
          .to raise_error ROM::Migrator::Errors::ContentError, /'#{number}'/
      end
    end

    it_behaves_like :raising_content_error do
      let(:number) { "" }
    end

    it_behaves_like :raising_content_error do
      let(:content) { "ROM::Migrator.migration; WTF?!" }
    end

    it_behaves_like :raising_content_error do
      let(:content) { "ROM::Migrator.migration; String" }
    end

    it_behaves_like :raising_content_error do
      let(:content) { "ROM::Migrator.migration; nil" }
    end
  end # describe #to_migration

end # describe ROM::Migrator::MigrationFile
