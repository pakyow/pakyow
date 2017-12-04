require "json"

RSpec.describe "route params" do
  include_context "testable app"

  context "when set on the controller" do
    let :app_definition do
      Proc.new {
        controller "/:input" do
          default do
            send params[:input]
          end
        end
      }
    end

    it "is available" do
      expect(call("/foo")[2].body.read).to eq("foo")
    end
  end

  context "when set as a named capture on a regex controller matcher" do
    let :app_definition do
      Proc.new {
        controller(/\/(?<input>.*)/) do
          default do
            send params[:input]
          end
        end
      }
    end

    it "is available" do
      expect(call("/foo")[2].body.read).to eq("foo")
    end
  end

  context "when set as a named capture on a custom controller matcher" do
    let :app_definition do
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
      expect(call("/foo")[2].body.first).to eq("bar")
    end
  end

  context "when set on the route" do
    let :app_definition do
      Proc.new {
        controller do
          get "/:input" do
            send params[:input]
          end
        end
      }
    end

    it "is available" do
      expect(call("/foo")[2].body.read).to eq("foo")
    end
  end

  context "when set as a named capture on a regex route matcher" do
    let :app_definition do
      Proc.new {
        controller do
          get(/\/(?<input>.*)/) do
            send params[:input]
          end
        end
      }
    end

    it "is available" do
      expect(call("/foo")[2].body.read).to eq("foo")
    end
  end

  context "when set as a named capture on a custom route matcher" do
    let :app_definition do
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
      expect(call("/foo")[2].body.first).to eq("bar")
    end
  end

  context "when passed as a request param" do
    let :app_definition do
      Proc.new {
        controller do
          default do
            send params[:input]
          end
        end
      }
    end

    it "is available" do
      expect(call("/?input=foo")[2].body.read).to eq("foo")
    end
  end

  context "when the request is a json request" do
    let :app_definition do
      Proc.new {
        controller do
          default do
            send params[:foo] || ""
          end
        end
      }
    end

    before do
      # necessary because you can't set content-type on a mock request
      allow_any_instance_of(Rack::Request).to receive(:media_type).and_return(
        Pakyow::Middleware::JSONBody::JSON_TYPE
      )
    end

    it "makes the json body available" do
      expect(call("/", input: { foo: "bar" }.to_json)[2].body.read).to eq("bar")
    end
  end
end
