require "json"

RSpec.describe "route params" do
  include_context "testable app"

  context "when set on the router" do
    it "is available"
  end

  context "when set as a named capture on a regex router matcher" do
    it "is available"
  end

  context "when set as a named capture on a custom router matcher" do
    it "is available"
  end

  context "when set on the route" do
    let :app_definition do
      -> {
        router do
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
      -> {
        router do
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
    it "is available"
  end

  context "when passed as a request param" do
    let :app_definition do
      -> {
        router do
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
      -> {
        router do
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
