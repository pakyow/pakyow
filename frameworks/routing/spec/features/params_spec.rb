require "json"

RSpec.describe "route params" do
  include_context "app"

  context "when set on the controller" do
    let :app_def do
      Proc.new {
        controller "/:input" do
          default do
            send params[:input]
          end
        end
      }
    end

    it "is available" do
      expect(call("/foo")[0]).to eq(200)
      expect(call("/foo")[2]).to eq("foo")
    end

    it "requires the param" do
      expect(call("/")[0]).to eq(404)
    end
  end

  context "when set as a named capture on a regex controller matcher" do
    let :app_def do
      Proc.new {
        controller(/\/(?<input>.*)/) do
          default do
            send params[:input]
          end
        end
      }
    end

    it "is available" do
      expect(call("/foo")[2]).to eq("foo")
    end
  end

  context "when set as a named capture on a custom controller matcher" do
    let :app_def do
      Proc.new {
        class CustomRouterMatcherWithCaptures
          def match?(path)
            true
          end

          def match(path)
            self
          end

          def named_captures
            { "foo" => "bar" }
          end
        end

        controller CustomRouterMatcherWithCaptures.new do
          get "/foo" do
            send params[:foo] || ""
          end
        end
      }
    end

    it "is available" do
      expect(call("/foo")[2]).to eq("bar")
    end
  end

  context "when set on the route" do
    let :app_def do
      Proc.new {
        controller do
          get "/:input" do
            send params[:input]
          end
        end
      }
    end

    it "is available" do
      expect(call("/foo")[0]).to eq(200)
      expect(call("/foo")[2]).to eq("foo")
    end

    it "requires the param" do
      expect(call("/")[0]).to eq(404)
    end
  end

  context "when set as a named capture on a regex route matcher" do
    let :app_def do
      Proc.new {
        controller do
          get(/\/(?<input>.*)/) do
            send params[:input]
          end
        end
      }
    end

    it "is available" do
      expect(call("/foo")[2]).to eq("foo")
    end
  end

  context "when set as a named capture on a custom route matcher" do
    let :app_def do
      Proc.new {
        class CustomRouteMatcherWithCaptures
          def match?(path)
            true
          end

          def match(path)
            self
          end

          def named_captures
            { "foo" => "bar" }
          end
        end

        controller do
          get CustomRouteMatcherWithCaptures.new do
            send params[:foo] || ""
          end
        end
      }
    end

    it "is available" do
      expect(call("/foo")[2]).to eq("bar")
    end
  end

  context "when passed as a request param" do
    let :app_def do
      Proc.new {
        controller do
          default do
            send params[:input]
          end
        end
      }
    end

    it "is available" do
      expect(call("/?input=foo")[2]).to eq("foo")
    end
  end

  context "when the request is a json request" do
    let :app_def do
      Proc.new {
        controller do
          default do
            send params[:foo] || ""
          end
        end
      }
    end

    it "makes the json body available" do
      expect(call("/", input: StringIO.new({ foo: "bar" }.to_json), headers: { "content-type" => "application/json" })[2]).to eq("bar")
    end
  end

  describe "inheriting params through multiple controller" do
    let :app_def do
      Proc.new do
        controller do
          namespace "/foo/:foo" do
            namespace "/bar" do
              default do
                send params[:foo] || ""
              end
            end
          end
        end
      end
    end

    it "inherits" do
      expect(call("/foo/test/bar")[2]).to eq("test")
    end
  end
end
