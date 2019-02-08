RSpec.describe "overriding the request method" do
  include_context "app"

  let :app_init do
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
      expect(call("/", method: :post, params: { _method: "PATCH" })[2].read).to eq("PATCH /")
    end
  end

  context "request method is not post" do
    it "routes to the request method" do
      expect(call("/", method: :put, params: { _method: "PATCH" })[2].read).to eq("PUT /")
    end
  end
end
