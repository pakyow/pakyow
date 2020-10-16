RSpec.describe "global verifier" do
  include_context "app"

  it "exposes a verifier instance on the environment" do
    expect(Pakyow.verifier).to be_instance_of(Pakyow::Support::MessageVerifier)
  end

  it "sets the key properly" do
    expect(Pakyow.verifier.key).to eq(Pakyow.config.secrets.first)
  end

  describe "error conditions" do
    let :autorun do
      false
    end

    let :error_message do
      "Pakyow will not boot without a secret configured in `Pakyow.config.secrets`"
    end

    context "no secrets are available" do
      before do
        Pakyow.config.secrets = []
      end

      it "raises an error" do
        expect {
          setup_and_run
        }.to raise_error do |error|
          expect(error.to_s).to include(error_message)
        end
      end
    end

    context "no non-empty secrets are available" do
      before do
        Pakyow.config.secrets = [""]
      end

      it "raises an error" do
        expect {
          setup_and_run
        }.to raise_error do |error|
          expect(error.to_s).to include(error_message)
        end
      end
    end

    context "no non-nil secrets are available" do
      before do
        Pakyow.config.secrets = [nil]
      end

      it "raises an error" do
        expect {
          setup_and_run
        }.to raise_error do |error|
          expect(error.to_s).to include(error_message)
        end
      end
    end
  end
end
