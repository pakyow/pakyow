RSpec.describe "overriding the request method" do
  include_context "app"

  let :app_def do
    Proc.new {
      controller do
        disable_protection :csrf

        put "/" do
          send "PUT /"
        end

        patch "/" do
          send "PATCH /"
        end
      end
    }
  end

  context "request method is post" do
    it "routes to the overriden method" do
      expect(call("/", method: :post, params: { :"pw-http-method" => "PATCH" })[2]).to eq("PATCH /")
    end
  end

  context "request method is not post" do
    it "routes to the request method" do
      expect(call("/", method: :put, params: { :"pw-http-method" => "PATCH" })[2]).to eq("PUT /")
    end
  end
end
