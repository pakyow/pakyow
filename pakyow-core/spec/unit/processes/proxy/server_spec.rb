RSpec.describe Pakyow::Processes::Proxy::Server do
  it "initializes with a port, host, and forwarded for value"

  describe "#call" do
    it "passes the request to the client"
    it "adds x-forwarded-to header to the request"

    context "request fails" do
      it "sleeps then retries"
      it "retries for 15s"
    end
  end
end
