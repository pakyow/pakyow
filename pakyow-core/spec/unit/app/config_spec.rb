RSpec.describe Pakyow::App do
  describe "configuration options" do
    let :app do
      Class.new(Pakyow::App)
    end

    describe "app" do
      it "can be extended with custom options" do
        app.config.app.foo = :bar
        expect(app.config.app.foo).to eq(:bar)
      end
    end

    describe "app.name" do
      it "has a default value" do
        expect(app.config.app.name).to eq("pakyow")
      end
    end

    describe "app.root" do
      it "has a default value" do
        expect(app.config.app.root).to eq(".")
      end
    end

    describe "app.src" do
      it "has a default value" do
        expect(app.config.app.src).to eq("./backend")
      end

      it "is dependent on `app.root`" do
        app.config.app.root = "ROOT"
        expect(app.config.app.src).to eq("ROOT/backend")
      end
    end

    describe "app.dsl" do
      it "has a default value" do
        expect(app.config.app.dsl).to eq(true)
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

    describe "protection.enabled" do
      it "has a default value" do
        expect(app.config.protection.enabled).to eq(true)
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
        app.config.app.name = "NAME"
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

    describe "session.options" do
      let :options do
        app.config.session.options
      end

      it "contains key" do
        expect(options[:key]).to eq("pakyow.session")
      end

      it "contains secret" do
        ENV["SESSION_SECRET"] = "foo"
        expect(options[:secret]).to eq("foo")
      end

      it "does not contain domain" do
        expect(options.keys).not_to include(:domain)
      end

      it "does not contain path" do
        expect(options.keys).not_to include(:path)
      end

      it "does not contain old_secret" do
        expect(options.keys).not_to include(:old_secret)
      end

      it "does not contain expire_after" do
        expect(options.keys).not_to include(:expire_after)
      end

      context "when expiry is set" do
        before do
          app.config.session.expiry = 1
        end

        it "contains expire_after" do
          expect(options[:expire_after]).to eq(1)
        end
      end

      context "when domain is set" do
        before do
          app.config.session.domain = "pakyow.org"
        end

        it "contains domain" do
          expect(options[:domain]).to eq("pakyow.org")
        end
      end

      context "when path is set" do
        before do
          app.config.session.path = "/foo"
        end

        it "contains path" do
          expect(options[:path]).to eq("/foo")
        end
      end

      context "when old_secret is set" do
        before do
          app.config.session.old_secret = "oldsekret"
        end

        it "contains old_secret" do
          expect(options[:old_secret]).to eq("oldsekret")
        end
      end
    end
  end
end
