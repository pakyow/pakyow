RSpec.describe "handling errors when calling the environment" do
  context "low-level error occurs" do
    before do
      Pakyow.action do |connection|
        fail "something went wrong"
      end
    end

    include_context "app"

    it "responds with the expected status" do
      expect(call("/")[0]).to eq(500)
    end

    it "responds with the expected headers" do
      expect(call("/")[1]).to eq({})
    end

    it "responds with the expected body" do
      expect(call("/")[2]).to eq("500 Low-Level Server Error")
    end
  end

  context "error occurs during dispatch" do
    include_context "app"

    let :app_def do
      Proc.new do
        action do |connection|
          fail "something went wrong"
        end
      end
    end

    let :allow_request_failures do
      true
    end

    it "sets the error on the connection" do
      expect_any_instance_of(Pakyow::Connection).to receive(:error=) do |_, error|
        expect(error.message).to eq("something went wrong")
      end

      call("/")
    end

    it "logs the error with the connection logger" do
      logger_double = instance_double(Pakyow::Logger, prologue: nil, epilogue: nil)
      allow_any_instance_of(Pakyow::Connection).to receive(:logger).and_return(logger_double)
      expect(logger_double).to receive(:houston) do |error|
        expect(error.message).to eq("something went wrong")
      end

      call("/")
    end

    it "responds with the expected status" do
      expect(call("/")[0]).to eq(500)
    end

    it "responds with the expected body" do
      expect(call("/")[2]).to eq("500 Server Error")
    end
  end
end
