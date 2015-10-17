# encoding: utf-8

describe ROM::Migrator::ClassDSL do

  let(:klass)   { Class.new { extend ROM::Migrator::ClassDSL } }
  let(:gateway) { double(:gateway).as_null_object }

  describe "#settings" do
    subject { klass.settings }

    it { is_expected.to be_kind_of ROM::Migrator::Settings }
  end # describe #settings

  describe "#default_path" do
    subject { klass.default_path "foo/bar" }

    it "updates #settings" do
      expect { subject }
        .to change { klass.settings.path }
        .to "foo/bar"
    end
  end # describe #default_template

  describe "#default_template" do
    subject { klass.default_template "foo/bar" }

    it "updates #settings" do
      expect { subject }
        .to change { klass.settings.template }
        .to "foo/bar"
    end
  end # describe #default_template

  describe "#default_logger" do
    subject { klass.default_logger logger }

    let(:logger) { Logger.new StringIO.new }

    it "updates #settings" do
      expect { subject }
        .to change { klass.settings.logger }
        .to logger
    end
  end # describe #default_template

  describe "#default_counter" do
    subject { klass.default_counter { |x| x.to_i + 1 } }

    it "updates #settings" do
      expect { subject }
        .to change { klass.settings.counter[1] }
        .to 2
    end
  end # describe #default_counter

  describe "#registrar" do
    subject { klass.registrar }

    it "returns subclass of base registrar" do
      expect(subject.superclass).to eql ROM::Migrator::Registrar
    end
  end # describe #registrar

  describe "#prepare_registry" do
    subject { klass.prepare_registry(:whatever) { :foo } }

    it "updates #registrar" do
      expect { subject }
        .to change { klass.registrar.new(gateway).prepare_registry }
        .to :foo
    end

    it "fails without a block" do
      expect { klass.prepare_registry }.to raise_error NoMethodError
    end
  end # describe #prepare_registry

  describe "#registered" do
    subject { klass.registered { [:foo] } }

    it "updates #registrar" do
      expect { subject }
        .to change { klass.registrar.new(gateway).registered }
        .to [:foo]
    end
  end # describe #prepare_registry

  describe "#registered?" do
    subject { klass.registered? { |_| :foo } }

    it "updates #registrar" do
      expect { subject }
        .to change { klass.registrar.new(gateway).registered? 1 }
        .to :foo
    end
  end # describe #registered?

  describe "#register" do
    subject { klass.register { |_| :foo } }

    it "updates #registrar" do
      expect { subject }
        .to change { klass.registrar.new(gateway).register 1 }
        .to :foo
    end
  end # describe #register

  describe "#unregister" do
    subject { klass.unregister { |_| :foo } }

    it "updates #registrar" do
      expect { subject }
        .to change { klass.registrar.new(gateway).unregister 1 }
        .to :foo
    end
  end # describe #unregister

  describe "unexpected method" do
    subject { klass.reverse {} }

    it "fails" do
      expect { subject }.to raise_error NoMethodError
    end
  end # unexpected method

  describe "#migration" do
    subject { klass.migration { up { :foo } } }

    it "returns subclass of base migration" do
      expect(subject.superclass).to eql ROM::Migrator::Migration
      expect(subject.up.call).to eql :foo
    end
  end # describe #migration

end # describe ROM::Migrator::ClassDSL
