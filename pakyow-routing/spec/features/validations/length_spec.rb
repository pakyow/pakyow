RSpec.describe "email validation" do
  include_context "app"

  let :app_def do
    Proc.new do
      controller do
        verify :test do
          required :value do
            validate :length, minimum: 2, maximum: 3
          end
        end

        get :test, "/test"
      end
    end
  end

  context "value is not accepted" do
    it "responds 400" do
      expect(call("/test", params: { value: "b" })[0]).to eq(400)
    end
  end

  context "value is accepted" do
    it "responds 200" do
      expect(call("/test", params: { value: "br" })[0]).to eq(200)
    end
  end
end
