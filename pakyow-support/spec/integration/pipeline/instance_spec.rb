require "pakyow/support/pipeline"
require "pakyow/support/pipeline/object"

RSpec.describe "defining an action on a pipeline instance" do
  let :result do
    Class.new do
      include Pakyow::Support::Pipeline::Object

      attr_reader :results

      def initialize
        @results = []
      end

      def <<(result)
        @results << result
      end
    end
  end

  let :pipelined do
    Class.new do
      include Pakyow::Support::Pipeline
    end
  end

  let :instance do
    pipelined.new
  end

  before do
    instance.action :foo do |result|
      result << "foo"
    end

    instance.action :bar do |result|
      result << "bar"
    end
  end

  it "calls the pipeline" do
    expect(instance.call(result.new).results).to eq(["foo", "bar"])
  end

  describe "duping the instance" do
    let :duped do
      instance.dup
    end

    before do
      duped.action :baz do |result|
        result << "baz"
      end
    end

    it "maintains its own pipeline" do
      expect(instance.call(result.new).results).to eq(["foo", "bar"])
      expect(duped.call(result.new).results).to eq(["foo", "bar", "baz"])
    end
  end
end
