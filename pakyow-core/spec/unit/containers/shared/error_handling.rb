RSpec.shared_examples "service error handling" do
  context "SignalException occurs" do
    let(:error) {
      SignalException.new(:INT)
    }

    it "does not rescue the environment" do
      expect(Pakyow).not_to receive(:rescue!)

      service.new(**options).perform
    end
  end

  context "StandardError occurs" do
    let(:error) {
      StandardError.new
    }

    it "rescues the environment with a wrapped error" do
      expect(Pakyow).to receive(:rescue!) do |rescue_error|
        expect(rescue_error).to be_instance_of(Pakyow::EnvironmentError)
        expect(rescue_error.cause).to be(error)
      end

      service.new(**options).perform
    end
  end

  context "Pakyow::EnvironmentError occurs" do
    let(:error) {
      Pakyow::EnvironmentError.new
    }

    it "rescues the environment with the error" do
      expect(Pakyow).to receive(:rescue!).with(error)

      service.new(**options).perform
    end
  end

  context "Pakyow::ApplicationError occurs" do
    let(:error) {
      Pakyow::ApplicationError.build(underyling_error, context: application)
    }

    let(:underyling_error) {
      StandardError.new
    }

    let(:application) {
      instance_double(Pakyow::Application)
    }

    it "rescues the error context with the error" do
      expect(application).to receive(:rescue!).with(error)

      service.new(**options).perform
    end
  end
end
