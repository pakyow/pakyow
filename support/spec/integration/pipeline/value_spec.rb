require "pakyow/support/pipeline"

RSpec.describe "return values from pipelines" do
  let(:pipelined) {
    Class.new do
      include Pakyow::Support::Pipeline
    end
  }

  let(:instance) {
    instance = pipelined.new

    instance.action :foo do
      :foo
    end

    instance.action :bar do
      :bar
    end

    instance
  }

  it "returns the value from the last action" do
    expect(instance.call).to eq(:bar)
  end

  context "action halts" do
    let(:instance) {
      instance = pipelined.new

      instance.action :foo do
        halt :foo
      end

      instance
    }

    it "returns the halted value" do
      expect(instance.call).to eq(:foo)
    end
  end

  context "action rejects" do
    let(:instance) {
      instance = pipelined.new

      instance.action :foo do
        reject :foo
      end

      instance
    }

    it "returns the rejected value" do
      expect(instance.call).to eq(:foo)
    end
  end
end
