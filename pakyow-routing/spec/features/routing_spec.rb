RSpec.describe "routing requests" do
  include_context "app"

  let :app_def do
    Proc.new {
      controller do
        disable_protection :csrf

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
    expect(call("/", method: :get)[2]).to eq("GET /")
  end

  it "routes PUT requests" do
    expect(call("/", method: :put)[2]).to eq("PUT /")
  end

  it "routes POST requests" do
    expect(call("/", method: :post)[2]).to eq("POST /")
  end

  it "routes PATCH requests" do
    expect(call("/", method: :patch)[2]).to eq("PATCH /")
  end

  it "routes DELETE requests" do
    expect(call("/", method: :delete)[2]).to eq("DELETE /")
  end

  it "gracefully handles unsupported methods" do
    expect(call("/", method: :foo)[0]).to eq(404)
  end

  context "request method is head" do
    let :app_def do
      Proc.new do
        attr_accessor :called

        controller do
          disable_protection :csrf

          get "/" do
            app.called = true
            send "GET /"
          end
        end
      end
    end

    it "calls the matching get route" do
      call("/", method: :head)
      expect(Pakyow.apps.first.called).to be(true)
    end
  end

  context "when a default route is specified" do
    let :app_def do
      Proc.new {
        controller do
          default do
            send "default"
          end
        end
      }
    end

    it "is called for GET /" do
      expect(call("/")[2]).to eq("default")
    end
  end

  describe "the routing context" do
    let :app_def do
      Proc.new {
        controller do
          action :foo, only: [:default]

          def foo
            @state ||= "foo"
          end

          default do
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

    it "shares state across actions and routes" do
      expect(call[2]).to eq("foobar")
    end

    xit "shares state across reroutes" do
      expect(call("/rr")[2]).to eq("onetwo")
    end

    it "does not share state across requests" do
      call

      # if the ivar is kept around we'd see "foobarbar"
      expect(call[2]).to eq("foobar")
    end
  end

  context "when route is defined without a block" do
    let :app_def do
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

  context "when more than one route matches in the same controller" do
    let :app_def do
      Proc.new {
        controller do
          get "/foo" do
            send "one"
          end

          get "/foo" do
            send "two"
          end
        end
      }
    end

    it "only calls the first one" do
      expect(call("/foo")[2]).to eq("one")
    end
  end

  context "when more than one route matches in different controllers" do
    let :app_def do
      Proc.new {
        controller do
          get "/foo" do
            send "one"
          end
        end

        controller do
          get "/foo" do
            send "two"
          end
        end
      }
    end

    it "only calls the first one" do
      expect(call("/foo")[2]).to eq("one")
    end
  end

  context "when two child controllers match" do
    let :app_def do
      Proc.new {
        controller do
          namespace "/foo" do
            get "/" do
              send "one"
            end
          end

          namespace "/foo" do
            get "/" do
              send "two"
            end
          end
        end
      }
    end

    it "only calls the first one" do
      expect(call("/foo")[2]).to eq("one")
    end
  end

  context "when a post route is matched in a parent with a child" do
    let :app_def do
      Proc.new {
        controller "/posts" do
          skip :verify_same_origin
          skip :verify_authenticity_token

          post "/" do
            connection.body = StringIO.new("one")
          end

          group do
          end
        end
      }
    end

    it "only dispatches once" do
      expect(call("/posts", method: :post)[2]).to eq("one")
    end
  end

  context "when routing with a path containing an extension" do
    context "path does not exist" do
      it "responds 404" do
        expect(call("/posts")[0]).to eq(404)
        expect(call("/posts.xml")[0]).to eq(404)
      end
    end

    context "path exists, but does not respond to extension" do
      let :app_def do
      Proc.new {
        controller "/posts" do
          default do
            connection.body = StringIO.new("one")
          end
        end
      }
    end

      it "responds 404" do
        expect(call("/posts")[0]).to eq(200)
        expect(call("/posts.xml")[0]).to eq(404)
      end
    end
  end
end
