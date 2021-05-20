require "pakyow/support/pipeline"

RSpec.describe "calling a pipeline within another pipeline" do
  context "halt occurs in the child pipeline" do
    let(:pipelined) {
      local = self

      Class.new {
        include Pakyow::Support::Pipeline

        action :foo do |result|
          result << "foo"
        end

        action :bar do |result|
          local.nested_pipelined.new.call(result)
        end

        action :baz do |result|
          result << "baz"
        end
      }
    }

    let(:nested_pipelined) {
      Class.new {
        include Pakyow::Support::Pipeline

        action do |result|
          halt result
        end
      }
    }

    it "halts both pipelines" do
      expect(pipelined.new.call([])).to eq(["foo"])
    end
  end
end
