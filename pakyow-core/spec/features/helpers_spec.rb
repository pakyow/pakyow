RSpec.describe "defining helpers for an app" do
  include_context "app"

  context "helper type is unspecified" do
    let :app_def do
      Proc.new do
        helper :foo do; end
      end
    end

    it "defines the helpers in the global context" do
      expect(app.helpers_for_context(:global)).to include(Test::Helpers::Foo)
    end
  end

  context "helper type is specified" do
    let :app_def do
      Proc.new do
        helper :foo, type: :active do; end
      end
    end

    it "defines the helpers in the specified context" do
      expect(app.helpers_for_context(:active)).to include(Test::Helpers::Foo)
    end

    it "does not define the helpers in unspecified contexts" do
      expect(app.helpers_for_context(:global)).to_not include(Test::Helpers::Foo)
      expect(app.helpers_for_context(:passive)).to_not include(Test::Helpers::Foo)
    end
  end
end
