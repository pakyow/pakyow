require "pakyow/support/pipeline"
require "pakyow/support/pipeline/object"

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

  context "passing an object" do
    let(:result) {
      Class.new do
        include Pakyow::Support::Pipeline::Object
      end
    }

    let(:result_instance) {
      result.new
    }

    context "action halts an object" do
      let(:instance) {
        instance = pipelined.new

        instance.action :foo do |result|
          result.halt
        end

        instance
      }

      it "returns the halting value" do
        expect(instance.call(result_instance)).to be(result_instance)
      end
    end

    context "action rejects an object" do
      let(:instance) {
        instance = pipelined.new

        instance.action :foo do |result|
          result.reject
        end

        instance
      }

      it "returns the rejected value" do
        expect(instance.call(result_instance)).to be(result_instance)
      end
    end
  end
end
