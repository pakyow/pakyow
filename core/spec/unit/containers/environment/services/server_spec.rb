require_relative "../../shared/error_handling"

RSpec.describe "environment.server service" do
  include_context "runnable"

  let(:service) {
    Pakyow.container(:environment).service(:server)
  }

  let(:instance) {
    service.new(**options)
  }

  let(:options) {
    { config: config, env: "development" }
  }

  let(:config) {
    double(:config, server: server_config)
  }

  let(:server_config) {
    double(:server_config, count: count)
  }

  let(:count) {
    42
  }

  before do
    allow(Pakyow.container(:server)).to receive(:run)
  end

  it_behaves_like "service error handling" do
    before do
      expect(Pakyow).to receive(:boot).and_raise(error)
    end
  end

  describe "::prerun" do
    before do
      expect(Pakyow.container(:server).services.each.count).not_to eq(0)
    end

    let(:options) {
      { foo: "bar" }
    }

    it "calls prerun for each service in the server container" do
      Pakyow.container(:server).services.each do |service|
        expect(service).to receive(:prerun).with(**options)
      end

      service.prerun(options)
    end
  end

  describe "::postrun" do
    before do
      expect(Pakyow.container(:server).services.each.count).not_to eq(0)
    end

    let(:options) {
      { foo: "bar" }
    }

    it "calls postrun for each service in the server container" do
      Pakyow.container(:server).services.each do |service|
        expect(service).to receive(:postrun).with(**options)
      end

      service.postrun(options)
    end
  end

  describe "#count" do
    it "returns the configured count" do
      expect(instance.count).to eq(count)
    end

    it "loads the environment" do
      expect(Pakyow).to receive(:load).with(env: "development")

      instance.count
    end
  end

  describe "#perform" do
    let(:options) {
      { env: "development" }
    }

    it "boots with the env option" do
      expect(Pakyow).to receive(:boot).with(env: options[:env])

      instance.perform
    end

    it "deep freezes the environment" do
      expect(Pakyow).to receive(:deep_freeze)

      instance.perform
    end

    it "runs the garbage collector" do
      expect(GC).to receive(:start)

      instance.perform
    end

    it "runs the server container using the threaded strategy" do
      expect(Pakyow.container(:server)).to receive(:run).with(parent: instance, strategy: :threaded, **options)

      instance.perform
    end
  end
end
