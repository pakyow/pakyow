require_relative "../../shared/error_handling"

RSpec.describe "environment.server service" do
  include_context "runnable"

  let(:service) {
    Pakyow.container(:environment).service(:server)
  }

  let(:instance) {
    service.new(**options)
  }

  it_behaves_like "service error handling" do
    before do
      expect(Pakyow).to receive(:boot).and_raise(error)
    end

    let(:options) {
      super().tap do |options|
        options[:endpoint] = double(:endpoint, accept: nil)
      end
    }
  end

  before do
    allow(Async::HTTP::Endpoint).to receive(:parse).with(
      "#{scheme}://#{host}:#{port}"
    ).and_return(endpoint)

    allow(Async::Reactor).to receive(:run) do |&block|
      allow(Async::IO::SharedEndpoint).to receive(:bound).with(endpoint).and_return(bound_endpoint)
      allow(bound_endpoint).to receive(:wait).and_return(bound_endpoint)

      block.call
    end

    allow(Pakyow.logger).to receive(:<<)
  end

  let(:scheme) {
    "https"
  }

  let(:host) {
    "localhost"
  }

  let(:port) {
    3000
  }

  let(:endpoint) {
    double(:endpoint, protocol: protocol)
  }

  let(:protocol) {
    double(:protocol)
  }

  let(:bound_endpoint) {
    double(:bound_endpoint, accept: nil)
  }

  let(:options) {
    { config: config, env: "development" }
  }

  let(:config) {
    double(:config, server: server_config)
  }

  let(:server_config) {
    double(:server_config, scheme: scheme, host: host, port: port, count: count)
  }

  let(:count) {
    42
  }

  describe "::prerun" do
    it "sets the endpoint option" do
      service.prerun(options)

      expect(options[:endpoint]).to be(bound_endpoint)
    end

    it "sets the protocol option" do
      service.prerun(options)

      expect(options[:protocol]).to be(protocol)
    end

    it "logs the running text" do
      expect(Pakyow.logger).to receive(:<<).with("\e[34;1mPakyow › Development › https://localhost:3000\e[0m\e[3m\nUse Ctrl-C to shut down the environment.\e[0m")

      service.prerun(options)
    end

    context "stdout is not a tty" do
      before do
        allow($stdout).to receive(:tty?).and_return(false)
      end

      it "logs simpler running text" do
        expect(Pakyow.logger).to receive(:<<).with("Pakyow › Development › https://localhost:3000")

        service.prerun(options)
      end
    end

    context "environment is impolite" do
      before do
        Pakyow.config.polite = false
      end

      it "logs simpler running text" do
        expect(Pakyow.logger).not_to receive(:<<)

        service.prerun(options)
      end
    end
  end

  describe "::postrun" do
    before do
      service.prerun(options)
    end

    it "closes the endpoint" do
      expect(bound_endpoint).to receive(:close)

      service.postrun(options)
    end
  end

  describe "#count" do
    it "returns the configured count" do
      expect(instance.count).to eq(count)
    end
  end

  describe "#logger" do
    it "returns nil" do
      expect(instance.logger).to be(nil)
    end
  end

  describe "#perform" do
    before do
      service.prerun(options)
    end

    it "boots with the env option" do
      expect(Pakyow).to receive(:boot).with(env: options[:env])

      instance.perform
    end

    it "deep freezes the environment" do
      expect(Pakyow).to receive(:deep_freeze)

      instance.perform
    end

    it "runs the server" do
      expect(Pakyow::Server).to receive(:run).with(
        Pakyow,
        endpoint: bound_endpoint,
        protocol: protocol,
        scheme: scheme
      )

      instance.perform
    end

    context "environment is already booted" do
      before do
        Pakyow.boot(env: "development")
      end

      it "does not boot the environment" do
        expect(Pakyow).not_to receive(:boot)

        instance.perform
      end

      it "does not deep freeze the environment" do
        expect(Pakyow).not_to receive(:deep_freeze)

        instance.perform
      end

      it "runs the server" do
        expect(Pakyow::Server).to receive(:run).with(
          Pakyow,
          endpoint: bound_endpoint,
          protocol: protocol,
          scheme: scheme
        )

        instance.perform
      end
    end
  end

  describe "#shutdown" do
    before do
      allow(Pakyow).to receive(:apps).and_return(apps)
    end

    let(:apps) {
      [instance_double(Pakyow::Application)]
    }

    it "shuts down each application" do
      apps.each do |app|
        expect(app).to receive(:shutdown)
      end

      instance.shutdown
    end

    context "application fails to shutdown" do
      before do
        allow(apps[0]).to receive(:shutdown).and_raise(error)
      end

      let(:error) {
        Pakyow::ApplicationError.new
      }

      it "rescues the application" do
        expect(apps[0]).to receive(:rescue!).with(error)

        instance.shutdown
      end
    end
  end
end
