RSpec.describe "configuring an app" do
  include_context "app"

  context "when configured globally" do
    let :app_def do
      Proc.new do
        config.name = "config-test"
      end
    end

    it "is configured properly" do
      expect(app.config.name).to eq("config-test")
    end
  end

  context "when configured for an environment" do
    let :app_def do
      Proc.new do
        configure :test do
        end
        config.name = "config-env-test"
      end
    end

    let :app_init do
      Proc.new do
        def load_pipeline_defaults(pipeline)
          pipeline.action Proc.new { |connection|
            connection.body = config.name
            connection.halt
          }
        end
      end
    end

    it "is configured properly" do
      res = call
      expect(res[0]).to eq(200)
      expect(res[2]).to eq("config-env-test")
    end
  end
end

RSpec.describe "accessing the app's config" do
  include_context "app"

  context "when accessed internally" do
    let :app_def do
      Proc.new do
        config.name = "config-test"
      end
    end

    let :app_init do
      Proc.new do
        def load_pipeline_defaults(pipeline)
          pipeline.action Proc.new { |connection|
            connection.body = config.name
            connection.halt
          }
        end
      end
    end

    it "is accessible" do
      res = call
      expect(res[0]).to eq(200)
      expect(res[2]).to eq("config-test")
    end
  end

  context "when accessed externally" do
    let :app_def do
      Proc.new do
        config.name = "config-test"
      end
    end

    it "can be accessed externally" do
      expect(app.config.name).to eq("config-test")
    end
  end
end
