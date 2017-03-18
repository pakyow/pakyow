RSpec.describe "using sessions" do
  include_context "testable app"

  def define
    Pakyow::App.define do
      config.protection.enabled = false

      router do
        get "/get" do
          send session[:foo] || ""
        end

        get "/set/:value" do
          session[:foo] = params[:value]
        end
      end
    end
  end

  describe "setting a session value" do
    it "sets the value" do
      cookie = call("/set/bar")[1]["Set-Cookie"]
      expect(call("/get", "HTTP_COOKIE" => cookie)[2].body.read).to eq("bar")
    end
  end
end
