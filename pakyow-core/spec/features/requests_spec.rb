RSpec.describe "calling the environment with a request" do
  include_context "app"

  it "responds 404 for any path" do
    expect(call("/" + SecureRandom.hex(8))[0]).to eq(404)
  end

  it "responds with the default connection body" do
    expect(call("/" + SecureRandom.hex(8))[2]).to eq("404 Not Found")
  end

  context "action modifies the body but does not halt" do
    let :app_def do
      Proc.new do
        action do |connection|
          connection.body = StringIO.new("foo")
        end
      end
    end

    it "responds 404 for any path" do
      expect(call("/" + SecureRandom.hex(8))[0]).to eq(404)
    end

    it "responds with the default body" do
      expect(call("/" + SecureRandom.hex(8))[2]).to eq("404 Not Found")
    end
  end

  context "connection is halted" do
    let :app_def do
      Proc.new do
        action do |connection|
          connection.body = StringIO.new("foo")
          connection.set_header("foo", "bar")
          connection.halt
        end
      end
    end

    it "responds 200" do
      expect(call("/" + SecureRandom.hex(8))[0]).to eq(200)
    end

    it "responds with the connection body" do
      expect(call("/" + SecureRandom.hex(8))[2]).to eq("foo")
    end

    it "responds with the connection headers" do
      expect(call("/" + SecureRandom.hex(8))[1]).to include("foo" => ["bar"])
    end
  end

  context "request method is head" do
    let :app_def do
      Proc.new do
        action do |connection|
          connection.body = StringIO.new("foo")
          connection.set_header("foo", "bar")
          connection.halt
        end
      end
    end

    it "responds 200" do
      expect(call("/" + SecureRandom.hex(8), method: :head)[0]).to eq(200)
    end

    it "responds with the connection headers" do
      expect(call("/" + SecureRandom.hex(8), method: :head)[1]).to include("foo" => ["bar"])
    end
  end

  context "no mounted endpoints" do
    it "runs and 404s" do
      expect(call("/")[0]).to eq(404)
    end
  end

  context "app is mounted" do
    let :app_def do
      Proc.new do
        action do |connection|
          connection.halt
        end
      end
    end

    it "calls the app with the connection" do
      expect(call("/")[0]).to eq(200)
    end
  end

  context "app mounted at a path" do
    let :app_def do
      Proc.new do
        action do |connection|
          connection.halt
        end
      end
    end

    let :mount_path do
      "/foo"
    end

    it "calls the app for requests to paths at the mounted path" do
      expect(call("/foo")[0]).to eq(200)
    end

    it "does not call the app for requests to paths outside the mounted path" do
      expect(call("/fo")[0]).to eq(404)
      expect(call("/")[0]).to eq(404)
    end
  end

  context "with multiple apps mounted at a path" do
    let :app_def do
      local = self
      Proc.new do
        action do |connection|
          local.instance_variable_get(:@calls) << :root
        end
      end
    end

    let :env_def do
      local = self
      Proc.new do
        Pakyow.app :test2 do
          action do |connection|
            local.instance_variable_get(:@calls) << :foo
          end
        end
      end
    end

    before do
      @calls = []
    end

    it "calls the first application that accepts the request" do
      expect(call("/")[0]).to eq(404)
      expect(@calls).to eq([:root])
    end
  end
end
