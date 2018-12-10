RSpec.describe "Handling failures in pakyow environment setup" do
  before do
    allow(Pakyow).to receive(:exit)
    allow(Pakyow).to receive(:load).and_raise(error)
    allow(Pakyow).to receive(:logger).and_return(double(:logger, error: nil))
  end

  let :error do
    RuntimeError
  end

  it "logs" do
    expect(Pakyow.logger).to receive(:error).with("Pakyow failed to initialize.\n")
    expect(Pakyow.logger).to receive(:error).with(error: error)
    Pakyow.setup
  end

  it "exits" do
    expect(Pakyow).to receive(:exit)
    Pakyow.setup
  end
end
