RSpec.describe "exposing the endpoint in the request env" do
  include_context "app"

  describe "routes" do
    let :app_def do
      Proc.new {
        controller :endpoint, "/endpoint" do
          get :name, "name" do
            connection.body = StringIO.new(connection.get(:__endpoint_name).to_s)
          end

          get :path, "path" do
            connection.body = StringIO.new(connection.get(:__endpoint_path).to_s)
          end
        end
      }
    end

    it "exposes the endpoint name" do
      expect(call("/endpoint/name")[2]).to eq("name")
    end

    it "exposes the endpoint path" do
      expect(call("/endpoint/path")[2]).to eq("/endpoint/path")
    end
  end
end
