require "pakyow/routing"

RSpec.describe "configuring an app" do
  include_context "testable app"

  context "when configured globally" do
    let :app_definition do
      Proc.new {
        config.name = "config-test"
      }
    end

    it "is configured properly" do
      expect(app.config.name).to eq("config-test")
    end
  end

  context "when configured for an environment" do
    let :app_definition do
      Proc.new {
        configure :test do
          config.name = "config-env-test"
        end

        controller do
          default do
            send config.name
          end
        end
      }
    end

    it "is configured properly" do
      res = call
      expect(res[0]).to eq(200)
      expect(res[2].body.read).to eq("config-env-test")
    end
  end
end

RSpec.describe "accessing the app's config" do
  include_context "testable app"

  context "when accessed internally" do
    let :app_definition do
      Proc.new {
        config.name = "config-test"

        controller do
          default do
            send config.name
          end
        end
      }
    end

    it "is accessible" do
      res = call
      expect(res[0]).to eq(200)
      expect(res[2].body.read).to eq("config-test")
    end
  end

  context "when accessed externally" do
    let :app_definition do
      Proc.new {
        config.name = "config-test"
      }
    end

    it "can be accessed externally" do
      expect(app.config.name).to eq("config-test")
    end
  end
end
