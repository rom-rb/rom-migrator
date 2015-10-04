# encoding: utf-8

describe ROM::Gateway do
  before do
    module ROM::Custom
      Gateway  = Class.new(ROM::Gateway)  { adapter :custom }
      Migrator = Class.new(ROM::Migrator) { def prepare_registry; end }
    end
    ROM.register_adapter :custom, ROM::Custom
  end

  let(:gateway) { ROM::Custom::Gateway.new }

  describe "#migrator" do
    subject { gateway.migrator }

    context "when adapter is present" do
      it { is_expected.to be_kind_of ROM::Custom::Migrator }

      it "refers back to the gateway" do
        expect(subject.gateway).to eql gateway
      end
    end

    context "when adapter is absent" do
      before { ROM::Custom::Gateway.adapter :broken }

      it "fails" do
        expect { subject }.to raise_error do |error|
          expect(error).to be_kind_of ROM::AdapterNotPresentError
          expect(error.message).to include " broken "
          expect(error.message).to include " migrator "
        end
      end
    end
  end # describe #migrator

  after do
    ROM.send :remove_const, :Custom
  end
end # describe ROM::Gateway
