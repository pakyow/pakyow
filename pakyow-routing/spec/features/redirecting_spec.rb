RSpec.describe "redirecting requests" do
  include_context "app"

  let :app_init do
    Proc.new {
      controller :redirect do
        get "/redirect" do
          redirect "/destination"
        end

        get "/redirect_to_route" do
          redirect :redirect_destination
        end

        get "/redirect_to_route_with_params/:id" do
          redirect :redirect_destination_with_params, id: params[:id]
        end

        get "/redirect_with_custom_status" do
          redirect "/destination", as: 301
        end

        get :destination, "/destination"
        get :destination_with_params, "/destination/:id"
      end
    }
  end

  it "redirects to a path" do
    expect(call("/redirect")[1]["location"]).to eq("/destination")
  end

  it "redirects to a route" do
    expect(call("/redirect_to_route")[1]["location"]).to eq("/destination")
  end

  it "redirects to a route with params" do
    expect(call("/redirect_to_route_with_params/123")[1]["location"]).to eq("/destination/123")
  end

  describe "response status code" do
    it "defaults to 302" do
      expect(call("/redirect")[0]).to eq(302)
    end

    it "can be changed" do
      expect(call("/redirect_with_custom_status")[0]).to eq(301)
    end
  end

  context "app is mounted at a non-root path" do
    let :mount_path do
      "/foo"
    end

    it "redirects to a route" do
      expect(call("/foo/redirect_to_route")[1]["location"]).to eq("/foo/destination")
    end
  end
end
