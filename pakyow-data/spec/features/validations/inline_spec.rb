RSpec.describe "inline validation" do
  include_context "testable app"

  let :app_definition do
    Proc.new do
      instance_exec(&$data_app_boilerplate)

      controller do
        include Pakyow::Data::VerificationHelpers

        verify :test do
          required :value do
            validate do |value|
              value == "foo"
            end
          end
        end

        get :test, "/test"
      end
    end
  end

  context "value passes the inline validation" do
    it "responds 200" do
      expect(call("/test", params: { value: "foo" })[0]).to eq(200)
    end
  end

  context "value does not pass the inline validation" do
    it "responds 400" do
      expect(call("/test", params: { value: "bar" })[0]).to eq(400)
    end
  end
end
