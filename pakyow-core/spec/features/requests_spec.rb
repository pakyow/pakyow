RSpec.describe "sending requests to an app" do
  include_context "app"

  let :app_init do
    Proc.new do
      after :initialize, priority: :low do
        @__pipeline.action Proc.new { |connection|
          connection.body = "foo"
        }
      end
    end
  end

  it "responds 404 for any path" do
    expect(call("/" + SecureRandom.hex(8))[0]).to eq(404)
  end

  it "responds with the default connection body" do
    expect(call("/" + SecureRandom.hex(8))[2]).to eq(["404 Not Found"])
  end

  it "responds with the default connection headers" do
    expect(call("/" + SecureRandom.hex(8))[1]).to eq("Content-Type" => "text/plain")
  end

  context "connection is halted" do
    let :app_init do
      Proc.new do
        after :initialize, priority: :low do
          @__pipeline.action Proc.new { |connection|
            connection.body = "foo"
            connection.set_response_header("Foo", "Bar")
            connection.halt
          }
        end
      end
    end

    it "responds 200" do
      expect(call("/" + SecureRandom.hex(8))[0]).to eq(200)
    end

    it "responds with the connection body" do
      expect(call("/" + SecureRandom.hex(8))[2].body).to eq("foo")
    end

    it "responds with the connection headers" do
      expect(call("/" + SecureRandom.hex(8))[1]).to eq("Foo" => "Bar")
    end
  end

  context "request method is head" do
    let :app_init do
      Proc.new do
        after :initialize, priority: :low do
          @__pipeline.action Proc.new { |connection|
            connection.body = "foo"
            connection.set_response_header("Foo", "Bar")
            connection.halt
          }
        end
      end
    end

    it "responds with an empty body" do
      expect(call("/" + SecureRandom.hex(8), method: :head)[2].length).to eq(0)
    end
  end
end
