require "pakyow/plugin"

RSpec.describe "reflected state" do
  include_context "mirror"

  context "defined in the app" do
    include_context "reflectable app"

    context "no scope" do
      let :frontend_test_case do
        "state/no_scope"
      end

      it "does not discover any scopes" do
        expect(scopes).to be_empty
      end
    end

    context "non-form scope" do
      let :frontend_test_case do
        "state/non_form_scope"
      end

      it "discovers the correct scopes" do
        expect(scopes.count).to eq(1)
        expect(scopes[0].name).to eq(:post)
      end
    end

    context "scope defined on a single form" do
      let :frontend_test_case do
        "state/single_form_scope"
      end

      it "discovers the correct scopes" do
        expect(scopes.count).to eq(1)
        expect(scopes[0].name).to eq(:post)
      end
    end

    context "scope defined across multiple forms" do
      let :frontend_test_case do
        "state/distributed_form_scope"
      end

      it "discovers the correct scopes" do
        expect(scopes.count).to eq(1)
        expect(scopes[0].name).to eq(:post)
      end
    end

    context "scope for a plugin" do
      let :frontend_test_case do
        "state/scope_for_plugin"
      end

      it "does not discover any scopes" do
        expect(scopes).to be_empty
      end

      it "does not discover any endpoints" do
        expect(endpoints).to be_empty
      end
    end

    context "form for a plugin" do
      let :frontend_test_case do
        "state/form_for_plugin"
      end

      it "does not discover any scopes" do
        expect(scopes).to be_empty
      end

      it "does not discover any endpoints" do
        expect(endpoints).to be_empty
      end
    end

    context "endpoint for a plugin" do
      let :frontend_test_case do
        "state/endpoint_for_plugin"
      end

      it "discovers the correct scopes" do
        expect(scopes.count).to eq(1)
        expect(scopes[0].name).to eq(:post)
      end

      it "discovers the correct endpoints" do
        expect(endpoints.count).to eq(1)
      end
    end
  end

  context "defined within a plugin" do
    before do
      class TestPlugin < Pakyow::Plugin(:testable, File.join(__dir__, "support/plugin"))
      end
    end

    include_context "app"

    let :app_def do
      Proc.new do
        plug :testable, at: "/"
      end
    end

    it "does not discover any scopes" do
      expect(scopes).to be_empty
    end
  end

  context "defined within a plugged view" do
    before do
      class TestPlugin < Pakyow::Plugin(:testable, File.join(__dir__, "support/plugin"))
      end
    end

    include_context "app"

    let :app_def do
      Proc.new do
        plug :testable, at: "/"

        configure do
          config.root = File.join(__dir__, "support/app")
        end
      end
    end

    it "does not discover any scopes" do
      expect(scopes).to be_empty
    end
  end
end
