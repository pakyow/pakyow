RSpec.describe "data config" do
  let :config do
    Pakyow.config.data
  end

  describe "default_adapter" do
    it "has a default value" do
      expect(config.default_adapter).to eq(:sql)
    end
  end

  describe "logging" do
    it "has a default value" do
      expect(config.logging).to eq(false)
    end
  end

  describe "auto_migrate" do
    it "has a default value" do
      expect(config.auto_migrate).to eq(true)
    end

    context "in production" do
      before do
        Pakyow.configure!(:production)
      end

      it "has a default production value" do
        expect(config.auto_migrate).to eq(false)
      end
    end
  end

  describe "auto_migrate_always" do
    it "always migrates :memory" do
      expect(config.auto_migrate_always).to eq([:memory])
    end
  end

  describe "adapter" do
    it "has a default value" do
      expect(config.subscriptions.adapter).to eq(:memory)
    end

    context "in production" do
      before do
        Pakyow.configure!(:production)
      end

      it "has a default production value" do
        expect(config.subscriptions.adapter).to eq(:redis)
      end
    end
  end

  describe "adapter_options" do
    it "has a default value" do
      expect(config.subscriptions.adapter_options).to eq({})
    end

    context "in production" do
      before do
        Pakyow.configure!(:production)
      end

      it "has a production value" do
        expect(config.subscriptions.adapter_options).to eq(redis_url: "redis://127.0.0.1:6379", redis_prefix: "pw")
      end

      context "REDIS_URL env var is defined" do
        before do
          ENV["REDIS_URL"] = "!!!"
          Pakyow.configure!(:production)
        end

        after do
          ENV.delete("REDIS_URL")
        end

        it "uses the env var value" do
          expect(config.subscriptions.adapter_options).to eq(redis_url: "!!!", redis_prefix: "pw")
        end
      end
    end
  end
end

RSpec.describe "connections config" do
  let :config do
    Pakyow.config.data.connections
  end

  it "has a setting for each type" do
    Pakyow::Data::SUPPORTED_CONNECTION_TYPES.each do |type|
      expect(config.public_send(type)).to eq({})
    end
  end
end
