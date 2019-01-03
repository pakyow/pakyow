require "pakyow/support/pipelined"
require "pakyow/support/pipelined/haltable"

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
      include Pakyow::Support::Pipelined::Haltable

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
          throw :halt
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
