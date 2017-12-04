RSpec.describe "using sessions" do
  include_context "testable app"

  let :app_definition do
    Proc.new {
      config.protection.enabled = false

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
      cookie = call("/set/bar")[1]["Set-Cookie"]
      expect(call("/get", "HTTP_COOKIE" => cookie)[2].body.read).to eq("bar")
    end
  end
end
