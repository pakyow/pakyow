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
        expect(app.config.name).to eq("pakyow")
      end
    end

    describe "app.root" do
      it "has a default value" do
        expect(app.config.root).to eq(".")
      end
    end

    describe "app.src" do
      it "has a default value" do
        expect(app.config.src).to eq("./backend")
      end

      it "is dependent on `app.root`" do
        app.config.root = "ROOT"
        expect(app.config.src).to eq("ROOT/backend")
      end
    end

    describe "app.dsl" do
      it "has a default value" do
        expect(app.config.dsl).to eq(true)
      end
    end

    describe "cookies.path" do
      it "has a default value" do
        expect(app.config.cookies.path).to eq("/")
      end
    end

    describe "cookies.expiry" do
      it "has a default value" do
        expect(app.config.cookies.expiry).to eq(604800)
      end
    end

    describe "session.enabled" do
      it "has a default value" do
        expect(app.config.session.enabled).to eq(true)
      end
    end

    describe "session.key" do
      it "has a default value" do
        expect(app.config.session.key).to eq("pakyow.session")
      end

      it "is dependent on `app.name`" do
        app.config.name = "NAME"
        expect(app.config.session.key).to eq("NAME.session")
      end
    end

    describe "session.secret" do
      it "returns the value of ENV['SESSION_SECRET']" do
        ENV["SESSION_SECRET"] = "foo"
        expect(app.config.session.secret).to eq("foo")
      end
    end

    describe "session.object" do
      it "has a default value" do
        expect(app.config.session.object).to eq(Rack::Session::Cookie)
      end
    end

    describe "session.old_secret" do
      it "exists" do
        expect(app.config.session.old_secret).to be(nil)
      end
    end

    describe "session.expiry" do
      it "exists" do
        expect(app.config.session.expiry).to be(nil)
      end
    end

    describe "session.path" do
      it "exists" do
        expect(app.config.session.path).to be(nil)
      end
    end

    describe "session.domain" do
      it "exists" do
        expect(app.config.session.domain).to be(nil)
      end
    end

    describe "tasks.prelaunch" do
      it "exists" do
        expect(app.config.tasks.prelaunch).to eq([])
      end
    end
  end
end
