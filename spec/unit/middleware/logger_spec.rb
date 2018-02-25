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
    allow(Pakyow::Logger::RequestLogger).to receive(:new).with(:http).and_return(logger)
  end

  it "creates a new http request logger" do
    expect(Pakyow::Logger::RequestLogger).to receive(:new).with(:http)
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
    expect(logger).to receive(:epilogue).with(res[0])
    middleware.call(env)
  end

  it "calls the app between prologue and epilogue" do
    expect(logger).to receive(:prologue).with(env)
    expect(app).to receive(:call).with(env)
    expect(logger).to receive(:epilogue).with(res[0])
    middleware.call(env)
  end

  it "returns the result of calling the app" do
    expect(middleware.call(env)).to be(res)
  end
end
