require "../spec/helpers/config_helpers"

RSpec.describe "presenter configuration options" do
  include ConfigHelpers

  after do
    Pakyow::App.reset
  end

  describe "presenter.view_stores" do
    it "has a default value" do
      expect(Pakyow::App.config.presenter.view_stores).to eq({ default: "./app/views" })
    end

    it "is dependent on `app.root`" do
      Pakyow::App.config.app.root = "ROOT"
      expect(Pakyow::App.config.presenter.view_stores).to eq({ default: "ROOT/app/views" })
    end
  end

  describe "presenter.require_route" do
    it "has a default value" do
      expect(Pakyow::App.config.presenter.require_route).to eq(false)
    end

    context "in test" do
      it "defaults to true" do
        expect(config_defaults(Pakyow::App.config.presenter, :test).require_route).to eq(true)
      end
    end

    context "in production" do
      it "defaults to true" do
        expect(config_defaults(Pakyow::App.config.presenter, :production).require_route).to eq(true)
      end
    end
  end
end
