RSpec.describe "app verifier" do
  include_context "app"

  let :app_def do
    Proc.new do
      action do |connection|
        case connection.path
        when "/sign"
          connection.body = connection.verifier.sign("foo")
        when "/verify"
          connection.body = connection.verifier.verify(connection.params[:data])
        end

        connection.halt
      rescue => Pakyow::Support::MessageVerifier::TamperedMessage
        connection.body = "tampered"
        connection.halt
      end
    end
  end

  it "exposes a verifier" do
    expect(call("/sign")[2]).to be_instance_of(String)
  end

  it "verifies messages on subsequent requests" do
    response = call("/sign")

    expect(
      call(
        "/verify",
        params: { data: response[2] },
        headers: { "cookie" => response[1]["set-cookie"].join("\n")}
      )[2]
    ).to eq("foo")
  end

  it "fails to verify messages on subsequent requests without a valid key" do
    response = call("/sign")

    expect(
      call(
        "/verify",
        params: { data: response[2] }
      )[2]
    ).to eq("tampered")
  end

  context "sessions are disabled" do
    let :app_def do
      Proc.new do
        configure :test do
          config.session.enabled = false
        end

        action do |connection|
          connection.body = connection.verifier.inspect
          connection.halt
        end
      end
    end

    it "does not expose a verifier" do
      expect(call("/")[2]).to eq("nil")
    end
  end
end
