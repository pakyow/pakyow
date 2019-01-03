RSpec.describe Pakyow::Middleware::Logger do
  let :app do
    double
  end

  let :middleware do
    Pakyow::Middleware::Logger.new(app)
  end

  let :env do
    {}
  end

  let :res do
    [200, [], {}]
  end

  let :logger do
    double.as_null_object
  end

  before do
    allow(app).to receive(:call).and_return(res)
  end

  before do
    allow(Pakyow::RequestLogger).to receive(:new).with(:http).and_return(logger)
  end

  it "creates a new http request logger" do
    expect(Pakyow::RequestLogger).to receive(:new).with(:http)
    middleware.call(env)
  end

  it "sets rack.logger to request logger" do
    middleware.call(env)
    expect(env["rack.logger"]).to be(logger)
  end

  it "logs the prologue" do
    expect(logger).to receive(:prologue).with(env)
    middleware.call(env)
  end

  it "logs the epilogue" do
    expect(logger).to receive(:epilogue).with(res)
    middleware.call(env)
  end

  it "calls the app between prologue and epilogue" do
    expect(logger).to receive(:prologue).with(env)
    expect(app).to receive(:call).with(env)
    expect(logger).to receive(:epilogue).with(res)
    middleware.call(env)
  end

  it "returns the result of calling the app" do
    expect(middleware.call(env)).to be(res)
  end

  context "when silencer exists" do
    let :io do
      StringIO.new
    end

    let :logger do
      Pakyow::RequestLogger.new(:http, logger: Pakyow::Logger.new(io))
    end

    before do
      Pakyow::Middleware::Logger.silencers << Proc.new do |path_info|
        path_info.include?("foo")
      end
    end

    after do
      Pakyow::Middleware::Logger.silencers.clear
    end

    context "silencer is matched" do
      it "silences log output" do
        expect(logger).to receive(:prologue) do
          expect(logger.logger.level).to eq(Logger::ERROR)
        end

        expect(logger).to receive(:epilogue) do
          expect(logger.logger.level).to eq(Logger::ERROR)
        end

        middleware.call(Rack::PATH_INFO => "/foo")
      end
    end

    context "silencer is not matched" do
      it "does not silence log output" do
        expect(logger).to receive(:prologue)
        expect(logger).to receive(:epilogue)
        middleware.call(Rack::PATH_INFO => "/bar")
      end
    end
  end
end
