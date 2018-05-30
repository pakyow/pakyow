RSpec.describe Pakyow::Presenter::Behavior::Endpoints do
  let :object_with_behavior do
    Class.new do
      include Pakyow::Presenter::Behavior::Endpoints
    end
  end

  let :instance_with_behavior do
    object_with_behavior.new
  end

  describe "#install_endpoints" do
    before do
      allow(instance_with_behavior).to receive(:setup_non_contextual_endpoints)
    end

    let :current_endpoint do
      Pakyow::Connection::Endpoint.new("/", foo: { bar: :baz })
    end

    it "duplicates the current endpoint" do
      instance_with_behavior.install_endpoints([], current_endpoint: current_endpoint)
      expect(instance_with_behavior.instance_variable_get(:@current_endpoint)).not_to be(current_endpoint)
    end

    it "deep dups the current endpoint's params" do
      instance_with_behavior.install_endpoints([], current_endpoint: current_endpoint)
      expect(instance_with_behavior.instance_variable_get(:@current_endpoint).params).not_to be(current_endpoint.params)
      expect(instance_with_behavior.instance_variable_get(:@current_endpoint).params[:foo]).not_to be(current_endpoint.params[:foo])
    end
  end
end
