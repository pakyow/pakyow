RSpec.describe "routing requests" do
  include_context "testable app"

  let :app_definition do
    Proc.new {
      controller do
        get "/" do
          send "GET /"
        end

        put "/" do
          send "PUT /"
        end

        post "/" do
          send "POST /"
        end

        patch "/" do
          send "PATCH /"
        end

        delete "/" do
          send "DELETE /"
        end
      end
    }
  end

  it "routes GET requests" do
    expect(call("/", method: :get)[2].body.read).to eq("GET /")
  end

  it "routes PUT requests" do
    expect(call("/", method: :put)[2].body.read).to eq("PUT /")
  end

  it "routes POST requests" do
    expect(call("/", method: :post)[2].body.read).to eq("POST /")
  end

  it "routes PATCH requests" do
    expect(call("/", method: :patch)[2].body.read).to eq("PATCH /")
  end

  it "routes DELETE requests" do
    expect(call("/", method: :delete)[2].body.read).to eq("DELETE /")
  end

  context "when a default route is specified" do
    let :app_definition do
      Proc.new {
        controller do
          default do
            send "default"
          end
        end
      }
    end

    it "is called for GET /" do
      expect(call("/")[2].body.read).to eq("default")
    end
  end

  describe "the routing context" do
    let :app_definition do
      Proc.new {
        controller do
          def foo
            @state ||= "foo"
          end

          default before: [:foo] do
            @state << "bar"
            send @state
          end

          get "/rr" do
            @state = "one"
            reroute "/two"
          end

          get "/two" do
            @state << "two"
            send @state
          end
        end
      }
    end

    it "shares state across hooks and routes" do
      expect(call[2].body.read).to eq("foobar")
    end

    xit "shares state across reroutes" do
      expect(call("/rr")[2].body.read).to eq("onetwo")
    end

    it "does not share state across requests" do
      call

      # if the ivar is kept around we'd see "foobarbar"
      expect(call[2].body.read).to eq("foobar")
    end
  end

  context "when route is defined without a block" do
    let :app_definition do
      Proc.new {
        controller do
          default
        end
      }
    end

    it "still matches the route" do
      expect(call("/")[0]).to eq(200)
    end
  end

  context "when a route is defined within another controller" do
    let :app_definition do
      Proc.new {
        controller :api, "/api" do
        end

        controller do
          get "/foo" do
            send "foo"
          end

          within :api do
            get "/foo" do
              send "api/foo"
            end
          end
        end
      }
    end

    it "calls the route defined within the current controller" do
      expect(call("/foo")[0]).to eq(200)
      expect(call("/foo")[2].body.first).to eq("foo")
    end

    it "calls the route defined within the other controller" do
      expect(call("/api/foo")[0]).to eq(200)
      expect(call("/api/foo")[2].body.first).to eq("api/foo")
    end
  end

  context "when a route is defined within another controller that's deeply nested" do
    let :app_definition do
      Proc.new {
        controller :api, "/api" do
          namespace :v1, "/v1" do
          end
        end

        controller do
          get "/foo" do
            send "foo"
          end

          within :api, :v1 do
            get "/foo" do
              send "api/v1/foo"
            end
          end
        end
      }
    end

    it "calls the route defined within the current controller" do
      expect(call("/foo")[0]).to eq(200)
      expect(call("/foo")[2].body.first).to eq("foo")
    end

    it "calls the route defined within the other controller" do
      expect(call("/api/v1/foo")[0]).to eq(200)
      expect(call("/api/v1/foo")[2].body.first).to eq("api/v1/foo")
    end
  end
end
