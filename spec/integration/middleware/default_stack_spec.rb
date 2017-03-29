RSpec.describe "default middleware stack" do
  let :builder do
    double(Rack::Builder)
  end

  before do
    Pakyow.instance_variable_set(:@builder, builder)
    allow(builder).to receive(:use)
    Pakyow.setup
  end

  after do
    Pakyow.reset
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
