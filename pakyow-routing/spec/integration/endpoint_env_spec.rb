RSpec.describe "exposing the endpoint in the request env" do
  include_context "app"

  describe "routes" do
    let :app_init do
      Proc.new {
        controller :endpoint, "/endpoint" do
          get :name, "name" do
            res.body << req.env["pakyow.endpoint.name"]
          end

          get :path, "path" do
            res.body << req.env["pakyow.endpoint.path"]
          end
        end
      }
    end

    it "exposes the endpoint name" do
      expect(call("/endpoint/name")[2].body).to eq([:name])
    end

    it "exposes the endpoint path" do
      expect(call("/endpoint/path")[2].body).to eq(["/endpoint/path"])
    end
  end
end
