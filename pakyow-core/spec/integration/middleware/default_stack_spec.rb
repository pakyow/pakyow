RSpec.describe "default middleware stack" do
  let :builder do
    double(Rack::Builder)
  end

  context "by default" do
    before do
      Pakyow.instance_variable_set(:@builder, builder)

      allow(builder).to receive(:use)
      allow(builder).to receive(:to_app)
      allow(builder).to receive(:map) { |&block| builder.instance_exec(&block) }
      allow(builder).to receive(:run)

      Pakyow.app :test
      Pakyow.config.server.name = :mock
      Pakyow.setup(env: :test).run
    end

    it "uses Middleware::Normalizer" do
      expect(builder).to have_received(:use).with(
        Pakyow::Middleware::Normalizer
      )
    end
  end
end
