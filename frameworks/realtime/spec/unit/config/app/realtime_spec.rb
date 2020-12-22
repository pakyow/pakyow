RSpec.describe "app realtime config" do
  let :app do
    Pakyow.app(:test)
  end

  let :config do
    app.config.realtime
  end

  describe "path" do
    it "has a default value" do
      expect(config.path).to eq("pw-socket")
    end
  end

  describe "endpoint" do
    it "has a default value" do
      expect(config.endpoint).to be(nil)
    end
  end

  describe "log_initial_request" do
    it "has a default value" do
      expect(config.log_initial_request).to eq(false)
    end

    context "in production" do
      before do
        app.configure!(:production)
      end

      it "has a default value" do
        expect(config.log_initial_request).to eq(true)
      end
    end
  end
end
