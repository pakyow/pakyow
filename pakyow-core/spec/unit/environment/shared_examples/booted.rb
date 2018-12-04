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
  end

  it "calls booted on each app that responds to booted" do
    allow(apps[0]).to receive(:respond_to?)
    allow(apps[0]).to receive(:respond_to?).with(:booted).and_return(true)

    expect(apps[0]).to receive(:booted)
  end

  it "does not call booted on an app that does not respond to booted" do
    allow(apps[0]).to receive(:respond_to?)
    allow(apps[0]).to receive(:respond_to?).with(:booted).and_return(false)

    expect(apps[0]).to_not receive(:booted)
  end

  context "something goes wrong" do
    before do
      allow(apps[0]).to receive(:respond_to?)
      allow(apps[0]).to receive(:respond_to?).with(:booted).and_return(true)
      allow(apps[0]).to receive(:booted).and_raise(error)
      allow(error).to receive(:backtrace).and_return(backtrace)
      allow(Pakyow.logger).to receive(:error)
    end

    let :error do
      RuntimeError.new("test")
    end

    let :backtrace do
      [:foo, :bar, :baz]
    end

    it "logs the error and each line of the backtrace" do
      expect(Pakyow.logger).to receive(:error).with("Pakyow failed to boot: test")
      backtrace.each do |line|
        expect(Pakyow.logger).to receive(:error).with(line)
      end
    end

    it "exits" do
      expect(Pakyow).to receive(:exit)
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
    end

    it "does not call booted on an app that does not respond to booted" do
      allow(apps[0]).to receive(:respond_to?)
      allow(apps[0]).to receive(:respond_to?).with(:booted).and_return(false)

      expect(apps[0]).to_not receive(:booted)
    end
  end
end
