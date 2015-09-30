# # encoding: utf-8

describe ROM::Migrator::MigrationFiles, :memfs do
  include_context :migrations

  let(:files) { described_class.new(folders) }
  let(:not_found_error) { ROM::Migrator::Errors::NotFoundError }

  describe ".new" do
    subject { files }

    it { is_expected.to be_immutable }
  end # describe .new

  describe "#folders" do
    subject { files.folders }

    it { is_expected.to eql folders }
  end # describe #folders

  describe "#each" do
    context "with no block given" do
      subject { files.each }

      it { is_expected.to be_kind_of Enumerator }
    end

    context "with a block" do
      subject { files.map { |f| [f.number, f.klass, f.path] } }

      it "iterates via ordered collection of files" do
        expect(subject).to eql [
          ["1", "CreateUsers", "/db/migrate/1_create_users.rb"],
          ["2", "CreateRoles", "/spec/dummy/db/migrate/2_create_roles.rb"],
          ["3", "CreateAccounts", "/db/migrate/3_create_accounts.rb"]
        ]
      end
    end
  end # describe #each

  describe "#with_numbers" do
    context "empty" do
      subject { files.with_numbers }

      it "returns updated collection" do
        expect(subject).to be_kind_of described_class
        expect(subject.map(&:number)).to eql %w()
      end
    end

    context "one number" do
      subject { files.with_numbers("1") }

      it "returns updated collection" do
        expect(subject).to be_kind_of described_class
        expect(subject.map(&:number)).to eql %w(1)
      end
    end

    context "list of numbers" do
      subject { files.with_numbers("1", ["2"]) }

      it "returns updated collection" do
        expect(subject).to be_kind_of described_class
        expect(subject.map(&:number)).to eql %w(1 2)
      end
    end

    context "absent number" do
      subject { files.with_numbers("4") }

      it "fails" do
        expect { subject }.to raise_error do |error|
          expect(error).to be_kind_of not_found_error
          expect(error.message).to include "'4'"
          expect(error.message).to include "/db/migrate"
          expect(error.message).to include "/spec/dummy/db/migrate"
        end
      end
    end
  end # describe #with_numbers

  describe "#after_numbers" do
    context "empty" do
      subject { files.after_numbers }

      it { is_expected.to eql files }
    end

    context "one number" do
      subject { files.after_numbers("1") }

      it "returns updated collection" do
        expect(subject).to be_kind_of described_class
        expect(subject.map(&:number)).to eql %w(2 3)
      end
    end

    context "list of numbers" do
      subject { files.after_numbers("0", ["1"]) }

      it "returns updated collection" do
        expect(subject).to be_kind_of described_class
        expect(subject.map(&:number)).to eql %w(2 3)
      end
    end

    context "absent number" do
      subject { files.after_numbers("4") }

      it "returns updated collection" do
        expect(subject).to be_kind_of described_class
        expect(subject.map(&:number)).to eql %w()
      end
    end
  end # describe #after_numbers

  describe "#upto_number" do
    context "with value" do
      subject { files.upto_number("2") }

      it "returns updated collection" do
        expect(subject).to be_kind_of described_class
        expect(subject.map(&:number)).to eql %w(1 2)
      end
    end

    context "without value" do
      subject { files.upto_number }

      it { is_expected.to eql files }
    end
  end # describe #after_numbers

  describe "#last_number" do
    subject { files.last_number }

    it { is_expected.to eql "3" }

    context "when files are absent" do
      let(:files) { described_class.new }

      it { is_expected.to eql "" }
    end
  end # describe #after_numbers

end # describe ROM::Migrator::MigrationFiles
