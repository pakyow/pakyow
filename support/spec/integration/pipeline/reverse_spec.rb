require "pakyow/support/pipeline"

RSpec.describe "calling a pipeline in reverse" do
  let :result do
    Class.new do
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

      action :foo
      action :bar

      def foo(result)
        result << "foo"
      end

      def bar(result)
        result << "bar"
      end
    end
  end

  it "calls the pipeline" do
    expect(pipelined.new.rcall(result.new)).to eq(["bar", "foo"])
  end
end
