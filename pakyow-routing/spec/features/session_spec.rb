RSpec.describe "using sessions" do
  include_context "app"

  let :app_init do
    Proc.new {
      controller do
        get "/get" do
          send session[:foo] || ""
        end

        get "/set/:value" do
          session[:foo] = params[:value]
        end
      end
    }
  end

  describe "setting a session value" do
    it "sets the value" do
      cookie = call("/set/bar")[1]["set-cookie"][0]
      expect(call("/get", headers: { "cookie" => cookie })[2]).to eq("bar")
    end
  end
end
