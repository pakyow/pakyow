RSpec.describe Pakyow::Routing::Controller do
  let :env do
    {}
  end

  let :app do
    klass = Class.new(Pakyow::Application) do
      # don't freeze for these tests, because if we do
      # we won't be able to attach method spies
      def freeze; end
    end

    klass.new(:test, builder: Rack::Builder.new)
  end

  let :call_state do
    Pakyow::Connection.new(app, {})
  end

  let :controller do
    Pakyow::Routing::Controller.new(call_state)
  end

  before do
    class Pakyow::Paths
      # don't freeze for these tests, because if we do
      # we won't be able to attach method spies
      def freeze; end
    end
  end

  after do
    class Pakyow::Paths
      remove_method(:freeze)
    end
  end

  describe ".method_missing" do
    context "when a template is available" do
      before do
        Pakyow::Routing::Controller.template(:foo) do; end
      end

      it "expands the template" do
        expect(Pakyow::Routing::Controller).to receive(:expand).with(:foo)
        Pakyow::Routing::Controller.foo
      end
    end

    context "when a template is unavailable" do
      it "fails" do
        expect { Pakyow::Routing::Controller.bar }.to raise_error(NoMethodError)
      end
    end
  end

  describe ".respond_to_missing?" do
    context "when a template is available" do
      before do
        Pakyow::Routing::Controller.template(:foo) do; end
      end

      it "returns true" do
        expect(Pakyow::Routing::Controller.respond_to_missing?(:foo)).to eq(true)
      end
    end

    context "when a template is unavailable" do
      it "returns false" do
        expect(Pakyow::Routing::Controller.respond_to_missing?(:bar)).to eq(false)
      end
    end
  end
end
