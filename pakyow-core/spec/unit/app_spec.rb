require "../spec/helpers/config_helpers"

RSpec.describe Pakyow::App do
  include ConfigHelpers

  describe "known events" do
    it "includes `initialize`" do
      expect(Pakyow::App.known_events).to include(:initialize)
    end

    it "includes `configure`" do
      expect(Pakyow::App.known_events).to include(:configure)
    end

    it "includes `load`" do
      expect(Pakyow::App.known_events).to include(:load)
    end

    it "includes `freeze`" do
      expect(Pakyow::App.known_events).to include(:freeze)
    end
  end

  describe "configuration options" do
    after do
      Pakyow::App.reset
    end

    describe "app" do
      it "can be extended with custom options" do
        Pakyow::App.config.app.foo = :bar
        expect(Pakyow::App.config.app.foo).to eq(:bar)
      end
    end

    describe "app.name" do
      it "has a default value" do
        expect(Pakyow::App.config.app.name).to eq("pakyow")
      end
    end

    describe "app.root" do
      it "has a default value" do
        expect(Pakyow::App.config.app.root).to eq(".")
      end
    end

    describe "app.src" do
      it "has a default value" do
        expect(Pakyow::App.config.app.src).to eq("./backend")
      end

      it "is dependent on `app.root`" do
        Pakyow::App.config.app.root = "ROOT"
        expect(Pakyow::App.config.app.src).to eq("ROOT/backend")
      end
    end

    describe "app.inferred_naming" do
      it "has a default value" do
        expect(Pakyow::App.config.app.inferred_naming).to eq(true)
      end
    end

    describe "routing.enabled" do
      it "has a default value" do
        expect(Pakyow::App.config.routing.enabled).to eq(true)
      end

      context "in prototype" do
        it "defaults to false" do
          expect(config_defaults(Pakyow::App.config.routing, :prototype).enabled).to eq(false)
        end
      end
    end

    describe "cookies.path" do
      it "has a default value" do
        expect(Pakyow::App.config.cookies.path).to eq("/")
      end
    end

    describe "cookies.expiry" do
      it "has a default value" do
        expect(Pakyow::App.config.cookies.expiry).to eq(604800)
      end
    end

    describe "protection.enabled" do
      it "has a default value" do
        expect(Pakyow::App.config.protection.enabled).to eq(true)
      end
    end

    describe "session.enabled" do
      it "has a default value" do
        expect(Pakyow::App.config.session.enabled).to eq(true)
      end
    end

    describe "session.key" do
      it "has a default value" do
        expect(Pakyow::App.config.session.key).to eq("pakyow.session")
      end

      it "is dependent on `app.name`" do
        Pakyow::App.config.app.name = "NAME"
        expect(Pakyow::App.config.session.key).to eq("NAME.session")
      end
    end

    describe "session.secret" do
      it "returns the value of ENV['SESSION_SECRET']" do
        ENV["SESSION_SECRET"] = "foo"
        expect(Pakyow::App.config.session.secret).to eq("foo")
      end
    end

    describe "session.object" do
      it "has a default value" do
        expect(Pakyow::App.config.session.object).to eq(Rack::Session::Cookie)
      end
    end

    describe "session.old_secret" do
      it "exists" do
        expect(Pakyow::App.config.session.old_secret).to be(nil)
      end
    end

    describe "session.expiry" do
      it "exists" do
        expect(Pakyow::App.config.session.expiry).to be(nil)
      end
    end

    describe "session.path" do
      it "exists" do
        expect(Pakyow::App.config.session.path).to be(nil)
      end
    end

    describe "session.domain" do
      it "exists" do
        expect(Pakyow::App.config.session.domain).to be(nil)
      end
    end

    describe "session.options" do
      let :options do
        Pakyow::App.config.session.options
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
          Pakyow::App.config.session.expiry = 1
        end

        it "contains expire_after" do
          expect(options[:expire_after]).to eq(1)
        end
      end

      context "when domain is set" do
        before do
          Pakyow::App.config.session.domain = "pakyow.org"
        end

        it "contains domain" do
          expect(options[:domain]).to eq("pakyow.org")
        end
      end

      context "when path is set" do
        before do
          Pakyow::App.config.session.path = "/foo"
        end

        it "contains path" do
          expect(options[:path]).to eq("/foo")
        end
      end

      context "when old_secret is set" do
        before do
          Pakyow::App.config.session.old_secret = "oldsekret"
        end

        it "contains old_secret" do
          expect(options[:old_secret]).to eq("oldsekret")
        end
      end
    end
  end

  describe ".reset" do
    it "calls super" do
      module SuperReset
        def reset
          super
          "called"
        end
      end

      class Pakyow::App
        extend SuperReset
      end

      expect(Pakyow::App.reset).to eq("called")
    end
  end

  describe "#initialize" do
    let :app do
      Pakyow::App.new(:test, builder: Rack::Builder.new)
    end

    it "sets the environment" do
      expect(app.environment).to eq(:test)
    end

    it "causes the app to load source" do
      skip "not a straight-forward thing to test"
    end

    context "when a builder is passed" do
      let :app do
        Pakyow::App.new(:test, builder: builder)
      end

      let :builder do
        Rack::Builder.new
      end

      it "sets the builder" do
        expect(app.builder).to eq(builder)
      end
    end
  end

  describe "#call" do
    let :env do
      { foo: "bar" }
    end

    let :app do
      Pakyow::App.new(:test, builder: Rack::Builder.new)
    end

    it "calls Pakyow::Controller.process" do
      expect(Pakyow::Controller).to receive(:process).with(env, app)
      app.call(env)
    end
  end

  describe "#freeze" do
    let :app do
      Pakyow::App.new(:test, builder: Rack::Builder.new)
    end

    before do
      Pakyow::App.before :freeze do
        $called = true
      end
    end

    it "calls before freeze hooks" do
      app.freeze
      expect($called).to be(true)
    end
  end
end
