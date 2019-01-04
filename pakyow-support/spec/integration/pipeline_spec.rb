require "pakyow/support/pipelined"
require "pakyow/support/pipelined/object"

RSpec.describe "using a pipeline" do
  let :pipelined do
    Class.new do
      include Pakyow::Support::Pipelined

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

  let :result do
    Class.new do
      include Pakyow::Support::Pipelined::Object

      attr_reader :results

      def initialize
        @results = []
      end

      def <<(result)
        @results << result
      end
    end
  end

  it "calls the pipeline" do
    expect(pipelined.new.call(result.new).results).to eq(["foo", "bar"])
  end

  describe "setting state as pipelined" do
    it "is not set to pipelined from the start" do
      expect(result.new.pipelined?).to be(false)
    end

    context "during pipelining" do
      let :pipelined do
        Class.new do
          include Pakyow::Support::Pipelined

          action :check

          def check(result)
            result << result.pipelined?
          end
        end
      end

      it "is not set to pipelined" do
        expect(pipelined.new.call(result.new).results).to eq([false])
      end
    end

    context "after pipelining" do
      it "is set to pipelined" do
        state = result.new
        pipelined.new.call(state)
        expect(state.pipelined?).to be(true)
      end
    end
  end

  context "action does not accept an argument" do
    let :pipelined do
      Class.new do
        include Pakyow::Support::Pipelined

        attr_reader :results

        def initialize
          @results = []
          super
        end

        action :foo
        action :bar

        def foo
          @results << "foo"
        end

        def bar
          @results << "bar"
        end
      end
    end

    it "calls the pipeline" do
      instance = pipelined.new
      instance.call(result.new)
      expect(instance.results).to eq(["foo", "bar"])
    end
  end

  context "an action halts" do
    let :pipelined do
      Class.new do
        include Pakyow::Support::Pipelined

        action :foo
        action :bar
        action :baz

        def foo(result)
          result << "foo"
        end

        def bar(result)
          result.halt
        end

        def baz(result)
          result << "baz"
        end
      end
    end

    it "calls the actions up to the halt" do
      expect(pipelined.new.call(result.new).results).to eq(["foo"])
    end
  end

  context "an action yields" do
    let :pipelined do
      Class.new do
        include Pakyow::Support::Pipelined

        action :foo
        action :bar
        action :baz

        def foo(result)
          result << "foo"
        end

        def bar(result)
          result << "bar1"
          yield
          result << "bar2"
        end

        def baz(result)
          result << "baz"
        end
      end
    end

    it "wraps the next actions" do
      expect(pipelined.new.call(result.new).results).to eq(["foo", "bar1", "baz", "bar2"])
    end

    context "action does not accept an argument" do
      let :pipelined do
        Class.new do
          include Pakyow::Support::Pipelined

          attr_reader :results

          def initialize
            @results = []
            super
          end

          action :foo
          action :bar
          action :baz

          def foo
            @results << "foo"
          end

          def bar
            @results << "bar1"
            yield
            @results << "bar2"
          end

          def baz
            @results << "baz"
          end
        end
      end

      it "wraps the next actions" do
        instance = pipelined.new
        instance.call(result.new)
        expect(instance.results).to eq(["foo", "bar1", "baz", "bar2"])
      end
    end
  end

  describe "using named pipelines" do
    let :pipelined do
      Class.new do
        include Pakyow::Support::Pipelined

        action :foo

        pipeline :bar do
          action :bar
        end

        def foo(result)
          result << "foo"
        end

        def bar(result)
          result << "bar"
        end
      end
    end

    it "replaces the actions of the current pipeline" do
      expect(pipelined.new.call(result.new).results).to eq(["foo"])

      pipelined.use_pipeline :bar
      expect(pipelined.new.call(result.new).results).to eq(["bar"])
    end
  end

  describe "including named pipelines" do
    let :pipelined do
      Class.new do
        include Pakyow::Support::Pipelined

        action :foo

        pipeline :bar do
          action :bar
        end

        def foo(result)
          result << "foo"
        end

        def bar(result)
          result << "bar"
        end
      end
    end

    it "includes the actions into the current pipeline" do
      expect(pipelined.new.call(result.new).results).to eq(["foo"])

      pipelined.include_pipeline :bar
      expect(pipelined.new.call(result.new).results).to eq(["foo", "bar"])
    end
  end

  describe "excluding named pipelines" do
    let :pipelined do
      Class.new do
        include Pakyow::Support::Pipelined

        action :foo
        action :bar

        pipeline :bar do
          action :bar
        end

        def foo(result)
          result << "foo"
        end

        def bar(result)
          result << "bar"
        end
      end
    end

    it "excludes the actions from the current pipeline" do
      expect(pipelined.new.call(result.new).results).to eq(["foo", "bar"])

      pipelined.exclude_pipeline :bar
      expect(pipelined.new.call(result.new).results).to eq(["foo"])
    end
  end
end
