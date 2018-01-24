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

  context "security.csrf is enabled" do
    before do
      Pakyow.instance_variable_set(:@builder, builder)

      allow(builder).to receive(:use)
      allow(builder).to receive(:to_app)
      allow(builder).to receive(:map) { |&block| builder.instance_exec(&block) }
      allow(builder).to receive(:run)

      Pakyow.app :test
      Pakyow.config.server.default = :mock
      Pakyow.config.security.csrf = true
      Pakyow.setup(env: :test).run
    end

    it "uses Security::Middleware::CSRF" do
      expect(builder).to have_received(:use).with(
        Pakyow::Security::Middleware::CSRF
      )
    end
  end

  context "security.csrf is disabled" do
    before do
      Pakyow.instance_variable_set(:@builder, builder)

      allow(builder).to receive(:use)
      allow(builder).to receive(:to_app)
      allow(builder).to receive(:map) { |&block| builder.instance_exec(&block) }
      allow(builder).to receive(:run)

      Pakyow.app :test
      Pakyow.config.server.default = :mock
      Pakyow.config.security.csrf = false
      Pakyow.setup(env: :test).run
    end

    it "does not use Security::Middleware::CSRF" do
      expect(builder).not_to have_received(:use).with(
        Pakyow::Security::Middleware::CSRF
      )
    end
  end
end
