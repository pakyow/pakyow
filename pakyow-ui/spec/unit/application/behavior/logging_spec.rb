RSpec.describe Pakyow::Application::Behavior::UI::Logging do
  describe "::log" do
    let :payload do
      {
        "severity" => "error",
        "message" => "foo"
      }
    end

    let :socket do
      double(logger: logger)
    end

    let :logger do
      double
    end

    it "logs the message at the severity using the socket's logger" do
      expect(logger).to receive(:error).with("foo")
      described_class.log(payload, socket)
    end
  end
end
