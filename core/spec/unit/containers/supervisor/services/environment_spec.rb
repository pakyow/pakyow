require_relative "../../shared/error_handling"

RSpec.describe "supervisor.environment service" do
  include_context "runnable"

  let(:service) {
    Pakyow.container(:supervisor).service(:environment)
  }

  let(:instance) {
    service.new(**options)
  }

  let(:options) {
    {}
  }

  before do
    allow(Pakyow.container(:environment)).to receive(:run)
  end

  it_behaves_like "service error handling" do
    before do
      expect(Pakyow).to receive(:boot).and_raise(error)
    end
  end

  describe "::prerun" do
    before do
      expect(Pakyow.container(:environment).services.each.count).not_to eq(0)
    end

    let(:options) {
      { foo: "bar" }
    }

    it "calls prerun for each service in the environment container" do
      Pakyow.container(:environment).services.each do |service|
        expect(service).to receive(:prerun).with(**options)
      end

      service.prerun(options)
    end
  end

  describe "::postrun" do
    before do
      expect(Pakyow.container(:environment).services.each.count).not_to eq(0)
    end

    let(:options) {
      { foo: "bar" }
    }

    it "calls postrun for each service in the environment container" do
      Pakyow.container(:environment).services.each do |service|
        expect(service).to receive(:postrun).with(**options)
      end

      service.postrun(options)
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

    it "runs the environment container" do
      expect(Pakyow.container(:environment)).to receive(:run).with(parent: instance, **options)

      instance.perform
    end
  end
end
