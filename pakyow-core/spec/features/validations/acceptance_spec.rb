RSpec.describe "acceptance validation" do
  include_context "testable app"

  let :app_definition do
    Proc.new do
      controller do
        verify :test do
          required :value, :boolean do
            validate :acceptance
          end
        end

        get :test, "/test"
      end
    end
  end

  context "value is not accepted" do
    it "responds 400" do
      expect(call("/test", params: { value: "false" })[0]).to eq(400)
    end
  end

  context "value is accepted" do
    it "responds 200" do
      expect(call("/test", params: { value: "true" })[0]).to eq(200)
    end
  end

  context "acceptance value is passed to the validator" do
    include_context "testable app"

    let :app_definition do
      Proc.new do
        controller do
          verify :test do
            required :value do
              validate :acceptance, accepts: ["foo", "bar"]
            end
          end

          get :test, "/test"
        end
      end
    end

    context "value is not accepted" do
      it "responds 400" do
        expect(call("/test", params: { value: "false" })[0]).to eq(400)
      end
    end

    context "value is accepted" do
      it "responds 200" do
        expect(call("/test", params: { value: "foo" })[0]).to eq(200)
      end
    end
  end
end
