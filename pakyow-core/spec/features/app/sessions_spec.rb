RSpec.describe "app sessions" do
  include_context "app"

  let :app_def do
    Proc.new do
      action do |connection|
        case connection.path
        when "/set"
          connection.session[:foo] = "bar"
        when "/get"
          connection.body = connection.session[:foo].to_s
        end

        connection.halt
      end
    end
  end

  it "sets values on the session" do
    expect(call("/set")[0]).to eq(200)
  end

  it "reads values from the session" do
    cookie = call("/set")[1]["set-cookie"][0]
    response = call("/get", headers: { "cookie" => cookie })
    expect(response[2]).to eq("bar")
  end

  context "sessions are disabled" do
    let :app_def do
      Proc.new do
        configure :test do
          config.session.enabled = false
        end

        action do |connection|
          connection.body = connection.session.inspect
          connection.halt
        end
      end
    end

    it "does not provide a session" do
      expect(call("/")[2]).to eq("nil")
    end
  end

  context "configured session object cannot be loaded" do
    let :app_def do
      Proc.new do
        configure :test do
          config.session.object = "missing"
        end
      end
    end

    let(:autorun) {
      false
    }

    it "raises an error" do
      expect {
        setup_and_run
      }.to raise_error(Pakyow::ApplicationError) do |error|
        expect(error.cause).to be_instance_of(LoadError)
      end
    end
  end

  context "session is reused across apps" do
    it "allows reuse"
  end
end
