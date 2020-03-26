require "pakyow/support/pipeline"

RSpec.describe "calling a pipeline without a pipeline object" do
  let(:pipelined) {
    Class.new {
      include Pakyow::Support::Pipeline

      action :foo do |result|
        result << "foo"
      end

      action :bar do |result|
        result << "bar"
      end
    }
  }

  it "calls the pipeline" do
    expect(pipelined.new.call([])).to eq(["foo", "bar"])
  end

  context "no arguments are passed" do
    let(:pipelined) {
      Class.new {
        include Pakyow::Support::Pipeline

        def results
          @results ||= []
        end

        action :foo do |arg = nil|
          results << ["foo", arg]
        end

        action :bar do |arg = nil|
          results << ["bar", arg]
        end
      }
    }

    let(:instance) {
      pipelined.new
    }

    it "calls the pipeline" do
      expect(instance.call).to be(nil)
      expect(instance.results[0]).to eq(["foo", nil])
      expect(instance.results[1]).to eq(["bar", nil])
    end
  end

  context "action halts" do
    let(:pipelined) {
      Class.new {
        include Pakyow::Support::Pipeline

        action :foo do |result|
          result << "foo"

          throw :halt
        end

        action :bar do |result|
          result << "bar"
        end
      }
    }

    it "calls the pipeline" do
      expect(pipelined.new.call([])).to eq(["foo"])
    end
  end

  context "action rejects" do
    let(:pipelined) {
      Class.new {
        include Pakyow::Support::Pipeline

        action :foo do |result|
          result << "foo"
        end

        action :bar do |result|
          throw :reject

          result << "bar"
        end

        action :baz do |result|
          result << "baz"
        end
      }
    }

    it "calls the pipeline" do
      expect(pipelined.new.call([])).to eq(["foo", "baz"])
    end
  end
end
