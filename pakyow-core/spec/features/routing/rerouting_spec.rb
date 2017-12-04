RSpec.describe "rerouting requests" do
  include_context "testable app"

  let :app_definition do
    Proc.new {
      controller :reroute do
        get "/reroute" do
          reroute "/destination"
        end

        get "/reroute_to_route" do
          reroute :reroute_destination
        end

        get "/reroute_to_route_with_params" do
          reroute :reroute_destination_with_params, id: params[:id]
        end

        get "/reroute_with_custom_status" do
          reroute "/destination", as: 301
        end

        get :destination, "/destination" do
          send "destination"
        end

        get :destination_with_params, "/destination/:id" do
          send "destination/#{params[:id]}"
        end
      end
    }
  end

  it "reroutes to a path" do
    res = call("/reroute")
    expect(res[0]).to eq(200)
    expect(res[2].body.first).to eq("destination")
  end

  it "reroutes to a route" do
    res = call("/reroute_to_route")
    expect(res[0]).to eq(200)
    expect(res[2].body.first).to eq("destination")
  end

  it "reroutes to a route with params" do
    res = call("/reroute_to_route_with_params", params: { id: "123" })
    expect(res[0]).to eq(200)
    expect(res[2].body.first).to eq("destination/123")
  end

  describe "the rerouted request" do
    it "reflects the rerouted path"
    it "reflects the rerouted method"
    it "makes the parent request available"
  end
end
