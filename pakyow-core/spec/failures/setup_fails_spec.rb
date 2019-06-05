RSpec.describe "Handling failures in pakyow environment setup" do
  include_context "app"

  before do
    allow(Pakyow).to receive(:exit)
    allow(Pakyow).to receive(:load).and_raise(error)
    allow(Pakyow).to receive(:logger).and_return(double(:logger, houston: nil))
    Pakyow.config.logger.enabled = true
  end

  let :error do
    RuntimeError
  end

  shared_examples :handling do
    it "logs" do
      expect(Pakyow.logger).to receive(:houston).with(error)
    end

    context "config.exit_on_boot_failure is true" do
      before do
        Pakyow.config.exit_on_boot_failure = true
      end

      it "exits" do
        expect(Pakyow).to receive(:exit).with(false)
      end
    end

    context "config.exit_on_boot_failure is false" do
      before do
        Pakyow.config.exit_on_boot_failure = false
      end

      it "does not exit" do
        expect(Pakyow).not_to receive(:exit)
      end
    end
  end

  before do
    Pakyow.setup
  end

  context "environment boots after a setup failure" do
    after do
      Pakyow.boot
    end

    include_examples :handling
  end
end
