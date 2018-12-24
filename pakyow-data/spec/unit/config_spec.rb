RSpec.describe "data config" do
  let :config do
    Pakyow.config.data
  end

  describe "default_adapter" do
    it "has a default value" do
      expect(config.default_adapter).to eq(:sql)
    end
  end

  describe "silent" do
    it "has a default value" do
      expect(config.silent).to eq(true)
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

  describe "adapter_settings" do
    it "has a default value" do
      expect(config.subscriptions.adapter_settings).to eq({})
    end

    context "in production" do
      before do
        Pakyow.configure!(:production)
      end

      it "defaults to global redis settings" do
        expect(config.subscriptions.adapter_settings.to_h).to eq(Pakyow.config.redis.to_h)
      end

      describe "changing the adapter settings" do
        it "does not affect the global settings" do
          config.subscriptions.adapter_settings.connection.tcp_keepalive = 15
          expect(Pakyow.config.redis.connection.tcp_keepalive).to eq(5)
        end
      end
    end
  end
end

RSpec.describe "connections config" do
  before do
    Pakyow.setup
  end

  let :config do
    Pakyow.config.data.connections
  end

  it "has a setting for each type" do
    Pakyow::Data::Connection.adapter_types.each do |type|
      expect(config.public_send(type)).to be_instance_of(Hash)
    end
  end
end
