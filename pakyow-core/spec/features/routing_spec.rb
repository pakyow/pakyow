RSpec.describe "routing requests" do
  include_context "testable app"

  let :app_definition do
    -> {
      router do
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
      -> {
        router do
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
      -> {
        router do
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

    it "shares state across reroutes" do
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
      -> {
        router do
          default
        end
      }
    end

    it "still matches the route" do
      expect(call("/")[0]).to eq(200)
    end
  end

  context "when route is a regex" do
    let :app_definition do
      -> {
        router do
          get(/.*/) do
            send "regex"
          end
        end
      }
    end

    it "still matches the route" do
      expect(call("/foo")[2].body.read).to eq("regex")
    end
  end

  context "when a route is defined for a specific format" do
    let :app_definition do
      -> {
        router do
          get "foo.txt" do
            send "foo"
          end
        end
      }
    end

    it "calls the route" do
      expect(call("/foo.txt")[2].body.first).to eq("foo")
    end

    context "and a request is received for an undefined format" do
      it "triggers a 404" do
        expect(call("/foo.json")[0]).to eq(404)
      end
    end
  end

  context "when multiple routes are defined, each for a specific format" do
    let :app_definition do
      -> {
        router do
          get "foo.txt" do
            send "foo"
          end

          get "foo.html" do
            send "<foo>"
          end
        end
      }
    end

    it "calls each route" do
      expect(call("/foo.txt")[2].body.first).to eq("foo")
      expect(call("/foo.html")[2].body.first).to eq("<foo>")
    end
  end

  context "when a route is defined for html format" do
    let :app_definition do
      -> {
        router do
          get "foo.html" do
            send "<foo>"
          end
        end
      }
    end

    it "calls the route with or without mentioning it in the request path" do
      expect(call("/foo")[2].body.first).to eq("<foo>")
      expect(call("/foo.html")[2].body.first).to eq("<foo>")
    end
  end

  context "when a route is defined for multiple formats" do
    let :app_definition do
      -> {
        router do
          get "foo.txt|html" do
          end
        end
      }
    end

    it "calls the route for each defined format" do
      expect(call("/foo.txt")[0]).to eq(200)
      expect(call("/foo.html")[0]).to eq(200)
    end

    context "and a request is received for an undefined format" do
      it "triggers a 404" do
        expect(call("/foo.json")[0]).to eq(404)
      end
    end

    context "and the route responds to a specific format" do
      let :app_definition do
        -> {
          router do
            get "foo.txt|html" do
              respond_to :txt do
                send "foo"
              end

              send "<foo>"
            end
          end
        }
      end

      it "receives the expected response" do
        expect(call("/foo.txt")[2].body.first).to eq("foo")
        expect(call("/foo.html")[2].body.first).to eq("<foo>")
      end

      it "sets the appropriate content type" do
        expect(call("/foo.txt")[1]['Content-Type']).to eq("text/plain")
        expect(call("/foo.html")[1]['Content-Type']).to eq("text/html")
      end
    end

    context "and the route responds to both formats" do
      let :app_definition do
        -> {
          router do
            get "foo.txt|html" do
              respond_to :txt do
                send "foo"
              end

              respond_to :html do
                send "<foo>"
              end
            end
          end
        }
      end

      it "receives the expected response" do
        expect(call("/foo.txt")[2].body.first).to eq("foo")
        expect(call("/foo.html")[2].body.first).to eq("<foo>")
      end

      it "sets the appropriate content type" do
        expect(call("/foo.txt")[1]['Content-Type']).to eq("text/plain")
        expect(call("/foo.html")[1]['Content-Type']).to eq("text/html")
      end
    end
  end

  context "when a route is defined in a group" do
    let :app_definition do
      -> {
        router do
          group :g, before: [:foo], after: [:foo], around: [:meh] do
            def foo
              $calls << :foo
            end

            def bar
              $calls << :bar
            end

            def baz
              $calls << :baz
            end

            def meh
              $calls << :meh
            end

            default before: [:bar], after: [:baz] do
              $calls << :route
            end
          end
        end
      }
    end

    before do
      $calls = []
    end

    it "is called" do
      expect(call[0]).to eq(200)
    end

    it "calls the hooks and route in order" do
      call

      expect($calls[0]).to eq(:meh)
      expect($calls[1]).to eq(:foo)
      expect($calls[2]).to eq(:bar)
      expect($calls[3]).to eq(:route)
      expect($calls[4]).to eq(:foo)
      expect($calls[5]).to eq(:baz)
      expect($calls[6]).to eq(:meh)
    end
  end

  context "when a route is defined in a namespace" do
    let :app_definition do
      -> {
        router do
          namespace :ns, "/ns", before: [:foo], after: [:foo], around: [:meh] do
            def foo
              $calls << :foo
            end

            def bar
              $calls << :bar
            end

            def baz
              $calls << :baz
            end

            def meh
              $calls << :meh
            end

            default before: [:bar], after: [:baz] do
              $calls << :route
            end
          end
        end
      }
    end

    before do
      $calls = []
    end

    it "is called" do
      expect(call("/ns")[0]).to eq(200)
    end

    it "calls the hooks and route in order" do
      call("/ns")

      expect($calls[0]).to eq(:meh)
      expect($calls[1]).to eq(:foo)
      expect($calls[2]).to eq(:bar)
      expect($calls[3]).to eq(:route)
      expect($calls[4]).to eq(:foo)
      expect($calls[5]).to eq(:baz)
      expect($calls[6]).to eq(:meh)
    end
  end

  context "when a route is defined within another router" do
    let :app_definition do
      -> {
        router :api, "/api" do
        end

        router do
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

    it "calls the route defined within the current router" do
      expect(call("/foo")[2].body.first).to eq("foo")
    end

    it "calls the route defined within the other router" do
      expect(call("/api/foo")[2].body.first).to eq("api/foo")
    end
  end

  context "when a route is defined within another router that's deeply nested" do
    let :app_definition do
      -> {
        router :api, "/api" do
          namespace :v1, "/v1" do
          end
        end

        router do
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

    it "calls the route defined within the current router" do
      expect(call("/foo")[2].body.first).to eq("foo")
    end

    it "calls the route defined within the other router" do
      expect(call("/api/v1/foo")[2].body.first).to eq("api/v1/foo")
    end
  end

  context "when part of a namespace is defined within another router" do
    let :app_definition do
      -> {
        router :api, "/api" do
        end

        router do
          namespace :foo, "/foo" do
            get "/bar" do
              send "foo/bar"
            end

            within :api do
              get "/bar" do
                send "api/foo/bar"
              end
            end
          end
        end
      }
    end

    it "calls the route defined within the current router" do
      expect(call("/foo/bar")[2].body.first).to eq("foo/bar")
    end

    it "calls the route defined within the other router" do
      expect(call("/api/foo/bar")[2].body.first).to eq("api/foo/bar")
    end
  end

  context "when part of a resource is defined within another router" do
    let :app_definition do
      -> {
        router :api, "/api" do
        end

        resource :project, "/projects" do
          list do
            send "project list"
          end

          within :api do
            list do
              send "project api list"
            end
          end
        end
      }
    end

    it "calls the route defined in the resource" do
      expect(call("/projects")[2].body.first).to eq("project list")
    end

    it "calls the route defined within the other router" do
      expect(call("/api/projects")[2].body.first).to eq("project api list")
    end
  end
end
