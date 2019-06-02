RSpec.describe Pakyow::App do
  describe "configuration options" do
    let :app do
      Class.new(Pakyow::App)
    end

    describe "app" do
      it "can be extended with custom options" do
        app.config.setting :foo, :bar
        expect(app.config.foo).to eq(:bar)
      end
    end

    describe "app.name" do
      it "has a default value" do
        expect(app.config.name).to eq(:pakyow)
      end
    end

    describe "app.root" do
      it "has a default value" do
        expect(app.config.root).to eq(File.expand_path("."))
      end
    end

    describe "app.src" do
      it "has a default value" do
        expect(app.config.src).to eq(File.join(Pakyow.config.root, "backend"))
      end

      it "is dependent on `app.root`" do
        app.config.root = "ROOT"
        expect(app.config.src).to eq("ROOT/backend")
      end
    end

    describe "app.version" do
      before do
        expect(Pakyow::Support::PathVersion).to receive(:build).with(app.config.src).and_return("digest")
      end

      it "has a default value" do
        expect(app.config.version).to eq("digest")
      end
    end

    describe "session.enabled" do
      it "has a default value" do
        expect(app.config.session.enabled).to eq(true)
      end
    end

    describe "session.object" do
      it "has a default value" do
        expect(app.config.session.object).to eq(:cookie)
      end
    end

    describe "session.cookie.name" do
      it "has a default value" do
        expect(app.config.session.cookie.name).to eq("pakyow.session")
      end

      it "is dependent on `app.name`" do
        app.config.name = "NAME"
        expect(app.config.session.cookie.name).to eq("NAME.session")
      end
    end

    %i(domain path max_age expires secure http_only same_site).each do |option|
      describe "session.cookie.#{option}" do
        it "has a default value"
        it "is dependent on Pakyow.config.cookie.#{option}"
      end
    end

    describe "tasks.prelaunch" do
      it "exists" do
        expect(app.config.tasks.prelaunch).to eq([])
      end
    end
  end
end
