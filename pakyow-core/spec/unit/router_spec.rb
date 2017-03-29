RSpec.describe Pakyow::Router do
  let :router do
    Pakyow::Router.new(controller)
  end

  let :controller do
    Pakyow::Controller.new({}, Pakyow::App.new(:test, builder: Rack::Builder.new))
  end

  describe "#initialize" do
    it "sets the controller" do
      expect(router.controller).to be(controller)
    end
  end

  describe ".method_missing" do
    context "when a template is available" do
      before do
        Pakyow::Router.template(:foo) do; end
      end

      it "expands the template" do
        expect(Pakyow::Router).to receive(:expand).with(:foo, {})
        Pakyow::Router.foo
      end
    end

    context "when a template is unavailable" do
      it "fails" do
        expect { Pakyow::Router.bar }.to raise_error(NoMethodError)
      end
    end
  end

  describe ".respond_to_missing?" do
    context "when a template is available" do
      before do
        Pakyow::Router.template(:foo) do; end
      end

      it "returns true" do
        expect(Pakyow::Router.respond_to_missing?(:foo)).to eq(true)
      end
    end

    context "when a template is unavailable" do
      it "returns false" do
        expect(Pakyow::Router.respond_to_missing?(:bar)).to eq(false)
      end
    end
  end

  describe "#logger" do
    it "delegates to `controller`" do
      expect(controller).to receive(:logger)
      router.logger
    end
  end

  describe "#handle" do
    it "delegates to `controller`" do
      expect(controller).to receive(:handle)
      router.handle(500)
    end
  end

  describe "#redirect" do
    it "delegates to `controller`" do
      expect(controller).to receive(:redirect).with("/foo")
      router.redirect("/foo")
    end
  end

  describe "#reroute" do
    it "delegates to `controller`" do
      expect(controller).to receive(:reroute).with("/foo")
      router.reroute("/foo")
    end
  end

  describe "#send" do
    it "delegates to `controller`" do
      expect(controller).to receive(:send).with("data")
      router.send("data")
    end
  end

  describe "#reject" do
    it "delegates to `controller`" do
      expect(controller).to receive(:reject)
      router.reject
    end
  end

  describe "#trigger" do
    it "delegates to `controller`" do
      expect(controller).to receive(:trigger).with(500)
      router.trigger(500)
    end
  end

  describe "#path" do
    it "delegates to `controller`" do
      expect(controller).to receive(:path).with("route")
      router.path("route")
    end
  end

  describe "#path_to" do
    it "delegates to `controller`" do
      expect(controller).to receive(:path_to).with("route")
      router.path_to("route")
    end
  end

  describe "#halt" do
    it "delegates to `controller`" do
      expect(controller).to receive(:halt)
      router.halt
    end
  end

  describe "#config" do
    it "delegates to `controller`" do
      expect(controller).to receive(:config)
      router.config
    end
  end

  describe "#params" do
    it "delegates to `controller`" do
      expect(controller).to receive(:params)
      router.params
    end
  end

  describe "#session" do
    it "delegates to `controller`" do
      expect(controller).to receive(:session)
      router.session
    end
  end

  describe "#cookies" do
    it "delegates to `controller`" do
      expect(controller).to receive(:cookies)
      router.cookies
    end
  end

  describe "#request" do
    it "delegates to `controller`" do
      expect(controller).to receive(:request)
      router.request
    end
  end

  describe "#response" do
    it "delegates to `controller`" do
      expect(controller).to receive(:response)
      router.response
    end
  end

  describe "#req" do
    it "delegates to `controller`" do
      expect(controller).to receive(:req)
      router.req
    end
  end

  describe "#res" do
    it "delegates to `controller`" do
      expect(controller).to receive(:res)
      router.res
    end
  end

  describe "#respond_to" do
    it "delegates to `controller`" do
      expect(controller).to receive(:respond_to).with(:html)
      router.respond_to(:html)
    end
  end
end
