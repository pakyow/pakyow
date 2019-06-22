RSpec.describe "subscriptions config" do
  let :app do
    Pakyow.app(:test)
  end

  let :config do
    app.config.data.subscriptions
  end

  describe "adapter_settings" do
    it "has a default value" do
      expect(config.adapter_settings).to eq({})
    end

    context "in production" do
      before do
        app.configure!(:production)
      end

      it "namespaces the key prefix with the app name" do
        expect(config.adapter_settings.to_h).to eq(key_prefix: "pw/test")
      end
    end
  end

  describe "version" do
    it "has a default value" do
      expect(config.version).to eq(nil)
    end
  end
end
