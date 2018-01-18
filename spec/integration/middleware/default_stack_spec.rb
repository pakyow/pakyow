RSpec.describe "default middleware stack" do
  let :builder do
    double(Rack::Builder)
  end

  before do
    allow(Pakyow).to receive(:builder_instance).and_return(builder)
    allow(builder).to receive(:use)
    allow(builder).to receive(:to_app)
    allow(builder).to receive(:map) { |&block| builder.instance_exec(&block) }
    allow(builder).to receive(:run)

    Pakyow.app :test
    Pakyow.config.server.default = :mock
    Pakyow.setup(env: :test).run
  end

  it "uses Rack::ContentType" do
    expect(builder).to have_received(:use).with(
      Rack::ContentType, "text/html"
    )
  end

  it "uses Rack::ContentLength" do
    expect(builder).to have_received(:use).with(
      Rack::ContentLength
    )
  end

  it "uses Rack::Head" do
    expect(builder).to have_received(:use).with(
      Rack::Head
    )
  end

  it "uses Rack::MethodOverride" do
    expect(builder).to have_received(:use).with(
      Rack::MethodOverride
    )
  end

  it "uses Middleware::JSONBody" do
    expect(builder).to have_received(:use).with(
      Pakyow::Middleware::JSONBody
    )
  end

  it "uses Middleware::Normalizer" do
    expect(builder).to have_received(:use).with(
      Pakyow::Middleware::Normalizer
    )
  end

  it "uses Middleware::Logger" do
    expect(builder).to have_received(:use).with(
      Pakyow::Middleware::Logger
    )
  end
end
