require "pakyow/support/pipeline"
require "pakyow/support/pipeline/object"

RSpec.describe "pipelines" do
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

  context "action references a method" do
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
      expect(pipelined.new.call(result.new).results).to eq(["foo", "bar"])
    end
  end

  context "action is an unnamed block" do
    let :pipelined do
      Class.new do
        include Pakyow::Support::Pipeline

        action do |result|
          result << "foo"
        end
      end
    end

    it "calls the pipeline" do
      expect(pipelined.new.call(result.new).results).to eq(["foo"])
    end
  end

  context "action is a named block" do
    let :pipelined do
      Class.new do
        include Pakyow::Support::Pipeline

        action :foo do |result|
          result << "foo"
        end
      end
    end

    it "calls the pipeline" do
      expect(pipelined.new.call(result.new).results).to eq(["foo"])
    end
  end

  context "action is a class" do
    let :pipelined do
      Class.new do
        include Pakyow::Support::Pipeline

        action Class.new {
          def call(result)
            result << "foo"
          end
        }
      end
    end

    it "calls the pipeline" do
      expect(pipelined.new.call(result.new).results).to eq(["foo"])
    end

    context "action is defined with options" do
      let :pipelined do
        Class.new do
          include Pakyow::Support::Pipeline

          action Class.new {
            def initialize(option)
              @option = option
            end

            def call(result)
              result << @option
            end
          }, "option"
        end
      end

      it "passes the options to the instance" do
        expect(pipelined.new.call(result.new).results).to eq(["option"])
      end
    end
  end

  context "action is a callable instance" do
    let :pipelined do
      Class.new do
        include Pakyow::Support::Pipeline

        action Proc.new { |result|
          result << "foo"
        }
      end
    end

    it "calls the pipeline" do
      expect(pipelined.new.call(result.new).results).to eq(["foo"])
    end
  end

  describe "setting state as pipelined" do
    it "is not set to pipelined from the start" do
      expect(result.new.pipelined?).to be(false)
    end

    context "during pipelining" do
      let :pipelined do
        Class.new do
          include Pakyow::Support::Pipeline

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
      let :pipelined do
        Class.new do
          include Pakyow::Support::Pipeline
        end
      end

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
        include Pakyow::Support::Pipeline

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
        include Pakyow::Support::Pipeline

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
        include Pakyow::Support::Pipeline

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
          include Pakyow::Support::Pipeline

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
        include Pakyow::Support::Pipeline

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
        include Pakyow::Support::Pipeline

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
        include Pakyow::Support::Pipeline

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

  describe "pipeline modules" do
    let :pipeline_module do
      Module.new do
        extend Pakyow::Support::Pipeline

        action :foo

        def foo(result)
          result << "foo"
        end

        action :bar do |result|
          result << "bar"
        end

        action Class.new {
          def call(result)
            result << "baz"
          end
        }

        action Proc.new { |result|
          result << "qux"
        }

        action do |result|
          result << "unnamed"
        end
      end
    end

    describe "using pipeline modules" do
      let :pipelined do
        Class.new do
          include Pakyow::Support::Pipeline

          action :current

          def current(result)
            result << "current"
          end
        end
      end

      it "replaces the actions of the current pipeline" do
        expect(pipelined.new.call(result.new).results).to eq(["current"])

        pipelined.use_pipeline pipeline_module
        expect(pipelined.new.call(result.new).results).to eq(["foo", "bar", "baz", "qux", "unnamed"])
      end
    end

    describe "including pipeline modules" do
      let :pipelined do
        Class.new do
          include Pakyow::Support::Pipeline

          action :current

          def current(result)
            result << "current"
          end
        end
      end

      it "includes the actions into the current pipeline" do
        expect(pipelined.new.call(result.new).results).to eq(["current"])

        pipelined.include_pipeline pipeline_module
        expect(pipelined.new.call(result.new).results).to eq(["current", "foo", "bar", "baz", "qux", "unnamed"])
      end
    end

    describe "excluding pipeline modules" do
      let :pipelined do
        Class.new do
          include Pakyow::Support::Pipeline

          action :current

          def current(result)
            result << "current"
          end
        end
      end

      it "excludes the actions from the current pipeline" do
        expect(pipelined.new.call(result.new).results).to eq(["current"])

        pipelined.include_pipeline pipeline_module
        pipelined.exclude_pipeline pipeline_module
        expect(pipelined.new.call(result.new).results).to eq(["current"])
      end
    end
  end
end
