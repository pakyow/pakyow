RSpec.describe "defining helpers for an app" do
  include_context "app"

  context "helper type is unspecified" do
    let :app_definition do
      Proc.new {
        helper :foo do; end
      }
    end

    it "defines the helpers in the global context" do
      expect(app.helpers(:global)).to include(Test::Helpers::Foo)
    end
  end

  context "helper type is specified" do
    let :app_definition do
      Proc.new {
        helper :foo, type: :active do; end
      }
    end

    it "defines the helpers in the specified context" do
      expect(app.helpers(:active)).to include(Test::Helpers::Foo)
    end

    it "does not define the helpers in unspecified contexts" do
      expect(app.helpers(:global)).to_not include(Test::Helpers::Foo)
      expect(app.helpers(:passive)).to_not include(Test::Helpers::Foo)
    end
  end
end
