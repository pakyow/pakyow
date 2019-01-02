RSpec.describe "Handling failures in pakyow environment setup" do
  before do
    Pakyow.app :test
    allow(Pakyow).to receive(:exit)
    allow(Pakyow).to receive(:load).and_raise(error)
    allow(Pakyow).to receive(:logger).and_return(double(:logger, error: nil))
    allow(Pakyow).to receive(:to_app)
    allow(Pakyow).to receive(:handler).and_return(double(:handler, run: nil))
  end

  let :error do
    RuntimeError
  end

  shared_examples :handling do
    it "logs" do
      expect(Pakyow.logger).to receive(:error).with(error: error)
    end

    context "config.exit_on_boot_failure is true" do
      before do
        Pakyow.config.exit_on_boot_failure = true
      end

      it "exits" do
        expect(Pakyow).to receive(:exit)
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

  context "environment runs after a setup failure" do
    after do
      Pakyow.run
    end

    include_examples :handling
  end
end
