# encoding: utf-8

describe ROM::Migrator::Functions do

  describe ".path_to_parts" do
    let(:arguments) { [:path_to_parts] }

    it_behaves_like :transforming_immutable_data do
      let(:input)  { "foo/bar_baz/num123_baz_qux.rb" }
      let(:output) { %w(Foo::BarBaz::BazQux num123) }
    end

    it_behaves_like :transforming_immutable_data do
      let(:input)  { "num123_baz_qux.rb" }
      let(:output) { %w(BazQux num123) }
    end

    it_behaves_like :transforming_immutable_data do
      let(:input)  { "foo/bar_baz/num123.rb" }
      let(:output) { [nil, nil] }
    end
  end # describe .path_to_parts

  describe ".parts_to_path" do
    let(:arguments) { [:parts_to_path] }

    it_behaves_like :transforming_immutable_data do
      let(:input)  { %w(Foo::BarBaz::BazQux num123) }
      let(:output) { "foo/bar_baz/num123_baz_qux.rb" }
    end

    it_behaves_like :transforming_immutable_data do
      let(:input)  { %w(BazQux num123) }
      let(:output) { "num123_baz_qux.rb" }
    end

    it_behaves_like :transforming_immutable_data do
      let(:input)  { [nil, "num123"] }
      let(:output) { "num123_.rb" }
    end

    it_behaves_like :transforming_immutable_data do
      let(:input)  { ["BarBaz::BazQux", nil] }
      let(:output) { "bar_baz/_baz_qux.rb" }
    end
  end # describe .parts_to_path

  describe ".split_path" do
    let(:arguments) { [:split_path] }

    it_behaves_like :transforming_immutable_data do
      let(:input)  { "foo/bar_baz/num123_baz_qux.rb" }
      let(:output) { ["foo/bar_baz", "num123", "baz_qux"] }
    end

    it_behaves_like :transforming_immutable_data do
      let(:input)  { "foo/bar_baz/num123.rb" }
      let(:output) { [nil, nil, nil] }
    end
  end # describe .split_path

  describe ".clean_array" do
    let(:arguments) { [:clean_array] }

    it_behaves_like :transforming_immutable_data do
      let(:input)  { [3, [2, nil], nil, 1] }
      let(:output) { [1, 2, 3] }
    end
  end # describe .clean_array

end # describe ROM::Migrator::Functions
