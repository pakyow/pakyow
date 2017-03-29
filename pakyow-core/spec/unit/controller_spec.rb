RSpec.describe Pakyow::Controller do
  describe "known events" do
    it "includes `process`" do
      expect(Pakyow::Controller.known_events).to include(:process)
    end

    it "includes `route`" do
      expect(Pakyow::Controller.known_events).to include(:route)
    end

    it "includes `error`" do
      expect(Pakyow::Controller.known_events).to include(:error)
    end

    it "includes `trigger`" do
      expect(Pakyow::Controller.known_events).to include(:trigger)
    end
  end

  let :controller do
    Pakyow::Controller.new(env, app)
  end

  let :env do
    {}
  end

  let :app do
    Pakyow::App.new(:test, builder: Rack::Builder.new)
  end

  describe "#initialize" do
    it "creates a request" do
      expect(Pakyow::Request).to receive(:new).with(env)
      controller
    end

    it "sets the request" do
      expect(controller.request.class).to be(Pakyow::Request)
    end

    it "creates a response" do
      expect(Pakyow::Response).to receive(:new)
      controller
    end

    it "sets the response" do
      expect(controller.response.class).to be(Pakyow::Response)
    end

    it "sets the app" do
      expect(controller.app).to be(app)
    end
  end

  describe "#logger" do
    it "delegates to `request`" do
      expect(controller.request).to receive(:logger)
      controller.logger
    end
  end

  describe "#params" do
    it "delegates to `request`" do
      expect(controller.request).to receive(:params)
      controller.params
    end
  end

  describe "#session" do
    it "delegates to `request`" do
      expect(controller.request).to receive(:session)
      controller.session
    end
  end

  describe "#cookies" do
    it "delegates to `request`" do
      expect(controller.request).to receive(:cookies)
      controller.cookies
    end
  end

  describe "#config" do
    it "delegates to `app`" do
      expect(controller.config).to be(controller.app.config)
    end
  end

  describe ".process" do
    it "creates a new instance" do
      expect(Pakyow::Controller).to receive(:new).with(env, app).and_return(instance_double(Pakyow::Controller).as_null_object)
      Pakyow::Controller.process(env, app)
    end

    it "processes" do
      expect_any_instance_of(Pakyow::Controller).to receive(:process)
      Pakyow::Controller.process(env, app)
    end
  end
end
