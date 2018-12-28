RSpec.describe "presence validation" do
  include_context "app"

  let :app_definition do
    Proc.new do
      controller do
        verify :test do
          required :value do
            validate :presence
          end
        end

        get :test, "/test"
      end
    end
  end

  context "value is not present" do
    it "responds 400" do
      expect(call("/test", params: { value: nil })[0]).to eq(400)
    end
  end

  context "value is present" do
    it "responds 200" do
      expect(call("/test", params: { value: "present" })[0]).to eq(200)
    end
  end
end
