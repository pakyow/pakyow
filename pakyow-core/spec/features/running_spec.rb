RSpec.describe "running the environment" do
  context "proxy is enabled" do
    it "starts the proxy on the host and port"
    it "starts the server on the host and discovered port"
    it "does not print the running text"
  end

  context "proxy is disabled" do
    it "starts the server on the host and port"
    it "does not start the proxy"
    it "prints the running text"

    context "environment is respawning" do
      it "does not print the running text"
    end
  end
end
