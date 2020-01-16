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
        app_class.before "load" do
          fail "testing rescue mode"
        end

        Pakyow.logger.set(Logger.new(File::NULL))

        app_class.setup
      end

      it "halts" do
        expect {
          app.call(connection)
        }.to throw_symbol(:halt)
      end

      it "enters rescue mode" do
        catch :halt do
          app.call(connection)
        end

        expect(connection.status).to eq(500)

        response_body = String.new
        while content = connection.body.read
          response_body << content
        end

        expect(response_body).to include("failed to initialize")
        expect(response_body).to include("testing rescue mode")
        expect(response_body).to include("pakyow-core/spec/unit/app_spec.rb")
      end
    end

    context "when setup fails because of a syntax error" do
      before do
        app_class.before "load" do
          eval("if")
        end

        Pakyow.logger.set(Logger.new(File::NULL))
      end

      it "enters rescue mode" do
        app_class.setup

        catch :halt do
          app.call(connection)
        end

        expect(connection.status).to eq(500)

        response_body = String.new
        while content = connection.body.read
          response_body << content
        end

        expect(response_body).to include("failed to initialize")
        expect(response_body).to include("syntax error, unexpected end-of-input")
        expect(response_body).to include("pakyow-core/spec/unit/app_spec.rb")
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

  describe "#boot" do
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

      it "enters rescue mode" do
        app.booted

        catch :halt do
          app.call(connection)
        end

        expect(connection.status).to eq(500)

        response_body = String.new
        while content = connection.body.read
          response_body << content
        end

        expect(response_body).to include("failed to initialize")
        expect(response_body).to include("testing rescue mode")
        expect(response_body).to include("pakyow-core/spec/unit/app_spec.rb")
      end
    end

    context "when booting fails because of a syntax error" do
      before do
        app_class.after "boot" do
          eval("if")
        end

        Pakyow.logger.set(Logger.new(File::NULL))
      end

      it "enters rescue mode" do
        app.booted

        catch :halt do
          app.call(connection)
        end

        expect(connection.status).to eq(500)

        response_body = String.new
        while content = connection.body.read
          response_body << content
        end

        expect(response_body).to include("failed to initialize")
        expect(response_body).to include("syntax error, unexpected end-of-input")
        expect(response_body).to include("pakyow-core/spec/unit/app_spec.rb")
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
