RSpec.describe "handling errors during a request lifecycle" do
  before do
    allow(Pakyow).to receive(:houston)
  end

  include_context "app"

  let(:allow_request_failures) {
    true
  }

  shared_examples :errors do
    it "responds with the expected status" do
      expect(call("/")[0]).to eq(500)
    end

    it "responds with the expected body" do
      expect(call("/")[2]).to eq("500 Server Error")
    end

    it "sets the error on the connection" do
      call("/")

      expect(connection.error.message).to eq("something went wrong")
    end

    it "reports the error" do
      expect(Pakyow).to receive(:houston) do |error|
        expect(error.message).to eq("something went wrong")
      end

      call("/")
    end
  end

  context "error occurs in the environment" do
    let(:app_def) {
      Proc.new {
        Pakyow.action do
          fail "something went wrong"
        end
      }
    }

    it_behaves_like :errors
  end

  context "error occurs in an application" do
    let(:app_def) {
      Proc.new {
        action do
          fail "something went wrong"
        end
      }
    }

    it_behaves_like :errors
  end

  context "error occurs within a handler" do
    let(:app_def) {
      Proc.new {
        Pakyow.action do
          fail "something went wrong"
        end

        Pakyow.handle do |*|
          fail "something went wrong"
        end
      }
    }

    it "responds with the expected status" do
      expect(call("/")[0]).to eq(500)
    end

    it "responds with the expected headers" do
      expect(call("/")[1]).to eq({})
    end

    it "responds with the expected body" do
      expect(call("/")[2]).to eq("500 Server Error")
    end
  end
end
