require "pakyow/application"

RSpec.describe Pakyow::Application do
  let :app_class do
    Pakyow::Application.make :test
  end

  let :connection do
    Pakyow::Connection.new(request)
  end

  let :request do
    instance_double(Async::HTTP::Protocol::Request)
  end

  before do
    allow(Pakyow).to receive(:output).and_return(
      double(:output, level: 2, verbose!: nil)
    )
  end

  describe "::setup" do
    describe "idempotence" do
      before do
        allow(app_class).to receive(:performing).and_call_original
      end

      it "is idempotent" do
        app_class.setup
        app_class.setup
        app_class.setup

        expect(app_class).to have_received(:performing).with(:setup).exactly(:once)
      end
    end

    context "when setup fails because of a runtime error" do
      before do
        app_class.before "load" do
          fail "testing rescue mode"
        end

        Pakyow.logger.set(Logger.new(File::NULL))
      end

      it "wraps the error in an application error" do
        expect {
          app_class.setup
        }.to raise_error(Pakyow::ApplicationError) do |error|
          expect(error.cause.message).to eq("testing rescue mode")
        end
      end
    end

    context "when setup fails because of a syntax error" do
      before do
        app_class.before "load" do
          ignore_warnings do
            eval("if")
          end
        end

        Pakyow.logger.set(Logger.new(File::NULL))
      end

      it "wraps the error in an application error" do
        expect {
          app_class.setup
        }.to raise_error(Pakyow::ApplicationError) do |error|
          expect(error.cause.message).to include("syntax error, unexpected end-of-input")
        end
      end
    end
  end

  describe "::setup?" do
    context "application is setup" do
      before do
        app_class.setup
      end

      it "returns true" do
        expect(app_class.setup?).to be(true)
      end
    end

    context "application is not setup" do
      it "returns false" do
        expect(app_class.setup?).to be(false)
      end
    end
  end

  describe "#initialize" do
    let :app do
      app_class.new(:test)
    end

    it "sets the environment" do
      expect(app.environment).to eq(:test)
    end

    it "causes the app to load source" do
      skip "not a straight-forward thing to test"
    end

    context "when initialization fails because of a runtime error" do
      before do
        app_class.before "initialize" do
          fail "testing rescue mode"
        end

        Pakyow.logger.set(Logger.new(File::NULL))
      end

      it "wraps the error in an application error" do
        expect {
          app_class.new
        }.to raise_error(Pakyow::ApplicationError) do |error|
          expect(error.cause.message).to eq("testing rescue mode")
        end
      end
    end

    context "when initialization fails because of a syntax error" do
      before do
        app_class.before "initialize" do
          ignore_warnings do
            eval("if")
          end
        end

        Pakyow.logger.set(Logger.new(File::NULL))
      end

      it "wraps the error in an application error" do
        expect {
          app_class.new
        }.to raise_error(Pakyow::ApplicationError) do |error|
          expect(error.cause.message).to include("syntax error, unexpected end-of-input")
        end
      end
    end
  end

  describe "#call" do
    let :env do
      { foo: "bar" }
    end

    let :app do
      app_class.new(:test)
    end

    it "calls each registered endpoint"
    it "passes common state between endpoints"

    context "when an endpoint halts" do
      it "sets cookies"
      it "returns response"
    end

    context "rack env includes a connection" do
      it "uses the given connection"
    end
  end

  describe "#booted" do
    let :app do
      app_class.new(:test)
    end

    before do
      app_class.after "boot" do
        $called_after_boot = true
      end
    end

    after do
      $called_after_boot = nil
    end

    it "calls after boot hooks" do
      app.booted
      expect($called_after_boot).to be(true)
    end

    context "when booting fails because of a runtime error" do
      before do
        app_class.after "boot" do
          fail "testing rescue mode"
        end

        Pakyow.logger.set(Logger.new(File::NULL))
      end

      it "wraps the error in an application error" do
        expect {
          app_class.new.booted
        }.to raise_error(Pakyow::ApplicationError) do |error|
          expect(error.cause.message).to eq("testing rescue mode")
        end
      end
    end

    context "when booting fails because of a syntax error" do
      before do
        app_class.after "boot" do
          ignore_warnings do
            eval("if")
          end
        end

        Pakyow.logger.set(Logger.new(File::NULL))
      end

      it "wraps the error in an application error" do
        expect {
          app_class.new.booted
        }.to raise_error(Pakyow::ApplicationError) do |error|
          expect(error.cause.message).to include("syntax error, unexpected end-of-input")
        end
      end
    end
  end

  describe "#shutdown" do
    let :app do
      app_class.new(:test)
    end

    before do
      app_class.before "shutdown" do
        $called_before_shutdown = true
      end
    end

    after do
      $called_before_shutdown = nil
    end

    it "calls before shutdown hooks" do
      app.shutdown
      expect($called_before_shutdown).to be(true)
    end

    context "when shutdown fails because of a runtime error" do
      before do
        app_class.before "shutdown" do
          fail "testing rescue mode"
        end

        Pakyow.logger.set(Logger.new(File::NULL))
      end

      it "wraps the error in an application error" do
        expect {
          app_class.new.shutdown
        }.to raise_error(Pakyow::ApplicationError) do |error|
          expect(error.cause.message).to eq("testing rescue mode")
        end
      end
    end

    context "when shutdown fails because of a syntax error" do
      before do
        app_class.before "shutdown" do
          ignore_warnings do
            eval("if")
          end
        end

        Pakyow.logger.set(Logger.new(File::NULL))
      end

      it "wraps the error in an application error" do
        expect {
          app_class.new.shutdown
        }.to raise_error(Pakyow::ApplicationError) do |error|
          expect(error.cause.message).to include("syntax error, unexpected end-of-input")
        end
      end
    end
  end

  describe "#top" do
    let :app do
      app_class.new(:test)
    end

    it "returns self" do
      expect(app.top).to be(app)
    end
  end
end
