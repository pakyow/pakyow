RSpec.shared_examples :environment_booted do
  before do
    allow(Pakyow).to receive(:call_hooks)
    allow(Pakyow).to receive(:exit)

    Pakyow.instance_variable_set(:@apps, apps)
  end

  let :apps do
    [double(:app)]
  end

  it "calls after boot hooks" do
    expect(Pakyow).to receive(:call_hooks).with(:after, :boot)
    perform
  end

  it "calls booted on each app that responds to booted" do
    allow(apps[0]).to receive(:respond_to?)
    allow(apps[0]).to receive(:respond_to?).with(:booted).and_return(true)

    expect(apps[0]).to receive(:booted)

    perform
  end

  it "does not call booted on an app that does not respond to booted" do
    allow(apps[0]).to receive(:respond_to?)
    allow(apps[0]).to receive(:respond_to?).with(:booted).and_return(false)

    expect(apps[0]).to_not receive(:booted)

    perform
  end

  context "something goes wrong" do
    before do
      allow(apps[0]).to receive(:respond_to?)
      allow(apps[0]).to receive(:respond_to?).with(:booted).and_return(true)
      allow(apps[0]).to receive(:booted).and_raise(error)
      allow(error).to receive(:backtrace).and_return(backtrace)
      allow(Pakyow::Support::Logging).to receive(:safe).and_yield(logger)
    end

    let :error do
      RuntimeError.new("test")
    end

    let :backtrace do
      [:foo, :bar, :baz]
    end

    let :logger do
      double(:logger, error: nil)
    end

    it "exposes the error" do
      perform
      expect(Pakyow.error).to be(error)
    end

    it "logs the error and each line of the backtrace" do
      expect(logger).to receive(:error).with(error)
      perform
    end

    it "exits" do
      expect(Pakyow).to receive(:exit)
      perform
    end
  end

  context "environment has already booted" do
    before do
      allow(Pakyow).to receive(:booted?).and_return(true)
    end

    it "calls booted on each app that responds to booted" do
      allow(apps[0]).to receive(:respond_to?)
      allow(apps[0]).to receive(:respond_to?).with(:booted).and_return(true)

      expect(apps[0]).to receive(:booted)

      perform
    end

    it "does not call booted on an app that does not respond to booted" do
      allow(apps[0]).to receive(:respond_to?)
      allow(apps[0]).to receive(:respond_to?).with(:booted).and_return(false)

      expect(apps[0]).to_not receive(:booted)

      perform
    end
  end
end
