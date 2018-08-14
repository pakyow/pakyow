RSpec.describe Pakyow::App do
  let :app_class do
    Class.new(Pakyow::App)
  end

  describe "#initialize" do
    let :app do
      app_class.new(:test, builder: Rack::Builder.new)
    end

    it "sets the environment" do
      expect(app.environment).to eq(:test)
    end

    it "causes the app to load source" do
      skip "not a straight-forward thing to test"
    end

    context "when a builder is passed" do
      let :app do
        app_class.new(:test, builder: builder)
      end

      let :builder do
        Rack::Builder.new
      end

      it "sets the builder" do
        expect(app.builder).to eq(builder)
      end
    end

    context "when initialization fails because of a runtime error" do
      before do
        app_class.before :load do
          fail "testing rescue mode"
        end

        Pakyow.instance_variable_set(:@logger, Logger.new(File::NULL))
      end

      it "enters rescue mode" do
        response = app.call({})
        expect(response[0]).to eq(500)
        expect(response[1]["Content-Type"]).to eq("text/plain")
        expect(response[2][0]).to include("failed to initialize")
        expect(response[2][0]).to include("testing rescue mode")
        expect(response[2][0]).to include("pakyow-core/spec/unit/app_spec.rb")
      end
    end

    context "when initialization fails because of a syntax error" do
      before do
        app_class.before :load do
          eval("if")
        end

        Pakyow.instance_variable_set(:@logger, Logger.new(File::NULL))
      end

      it "enters rescue mode" do
        app.booted
        response = app.call({})
        expect(response[0]).to eq(500)
        expect(response[1]["Content-Type"]).to eq("text/plain")
        expect(response[2][0]).to include("failed to initialize")
        expect(response[2][0]).to include("syntax error, unexpected end-of-input")
        expect(response[2][0]).to include("pakyow-core/spec/unit/app_spec.rb")
      end
    end
  end

  describe "#call" do
    let :env do
      { foo: "bar" }
    end

    let :app do
      app_class.new(:test, builder: Rack::Builder.new)
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

  describe "#boot" do
    let :app do
      app_class.new(:test, builder: Rack::Builder.new)
    end

    before do
      app_class.after :boot do
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
        app_class.after :boot do
          fail "testing rescue mode"
        end

        Pakyow.instance_variable_set(:@logger, Logger.new(File::NULL))
      end

      it "enters rescue mode" do
        app.booted
        response = app.call({})
        expect(response[0]).to eq(500)
        expect(response[1]["Content-Type"]).to eq("text/plain")
        expect(response[2][0]).to include("failed to initialize")
        expect(response[2][0]).to include("testing rescue mode")
        expect(response[2][0]).to include("pakyow-core/spec/unit/app_spec.rb")
      end
    end

    context "when booting fails because of a syntax error" do
      before do
        app_class.after :boot do
          eval("if")
        end

        Pakyow.instance_variable_set(:@logger, Logger.new(File::NULL))
      end

      it "enters rescue mode" do
        app.booted
        response = app.call({})
        expect(response[0]).to eq(500)
        expect(response[1]["Content-Type"]).to eq("text/plain")
        expect(response[2][0]).to include("failed to initialize")
        expect(response[2][0]).to include("syntax error, unexpected end-of-input")
        expect(response[2][0]).to include("pakyow-core/spec/unit/app_spec.rb")
      end
    end
  end

  describe "#forking" do
    let :app do
      app_class.new(:test, builder: Rack::Builder.new)
    end

    before do
      app_class.before :fork do
        $called_before_fork = true
      end
    end

    after do
      $called_before_fork = nil
    end

    it "calls before fork hooks" do
      app.forking
      expect($called_before_fork).to be(true)
    end
  end

  describe "#forked" do
    let :app do
      app_class.new(:test, builder: Rack::Builder.new)
    end

    before do
      app_class.after :fork do
        $called_after_fork = true
      end
    end

    after do
      $called_after_fork = nil
    end

    it "calls after fork hooks" do
      app.forked
      expect($called_after_fork).to be(true)
    end
  end
end
