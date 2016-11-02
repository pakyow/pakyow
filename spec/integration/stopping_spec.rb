RSpec.describe "stopping the environment" do
  before do
    allow(handler_double).to receive(:run).and_yield(server_double)
    allow(Pakyow).to receive(:handler).and_return(handler_double)
    Pakyow.instance_variable_set(:@builder, double.as_null_object)
    Pakyow.config.server.default = :mock

    expect(Pakyow).to receive(:trap).at_least(:once) do |signal, &block|
      if signal == trap_signal
        Pakyow.instance_eval(&block)
      end
    end
  end

  after do
    Pakyow.reset
  end

  let :handler_double do
    double
  end

  let :server_double do
    double
  end

  let :trap_double do
    double
  end

  shared_examples :shutdown do
    context "when server responds to `stop!`" do
      before do
        allow(server_double).to receive(:respond_to?) do |arg|
          arg == "stop!"
        end
      end

      it "stops without terminating the process" do
        expect(server_double).to receive(:send).with("stop!")
        expect(Process).not_to receive(:exit!)
        Pakyow.setup(env: :test).run
      end
    end

    context "when server responds to `stop`" do
      before do
        allow(server_double).to receive(:respond_to?) do |arg|
          arg == "stop"
        end
      end

      it "stops without terminating the process" do
        expect(server_double).to receive(:send).with("stop")
        expect(Process).not_to receive(:exit!)
        Pakyow.setup(env: :test).run
      end
    end

    context "when server does not respond to stop methods" do
      before do
        allow(server_double).to receive(:respond_to?).and_return(false)
      end

      it "terminates the process" do
        expect(Process).to receive(:exit!)
        Pakyow.setup(env: :test).run
      end
    end
  end

  context "when sent INT" do
    let :trap_signal do
      "INT"
    end

    include_examples :shutdown
  end

  context "when sent TERM" do
    let :trap_signal do
      "TERM"
    end

    include_examples :shutdown
  end
end
