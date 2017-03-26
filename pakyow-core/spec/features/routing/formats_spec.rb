RSpec.describe "route formats" do
  include_context "testable app"

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

    context "and the request path includes the format" do
      it "is called" do
        expect(call("/foo.html")[2].body.first).to eq("<foo>")
      end
    end

    context "and the request path includes the format" do
      it "is not called" do
        expect(call("/foo")[2].body.first).to eq(nil)
      end
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
end
