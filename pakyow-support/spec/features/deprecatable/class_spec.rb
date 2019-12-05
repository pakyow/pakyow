require "pakyow/support/deprecatable"

RSpec.describe "deprecating a class" do
  let(:deprecatable) {
    Class.new {
      extend Pakyow::Support::Deprecatable
    }.tap do |deprecatable|
      stub_const "DeprecatableClass", deprecatable
    end
  }

  before do
    allow(Pakyow::Support::Deprecator.global).to receive(:deprecated)

    deprecatable.class_eval do
      deprecate
    end
  end

  it "does not report the deprecation immediately" do
    expect(Pakyow::Support::Deprecator.global).not_to have_received(:deprecated)
  end

  context "class is initialized" do
    before do
      deprecatable.new
    end

    it "reports the deprecation" do
      expect(Pakyow::Support::Deprecator.global).to have_received(:deprecated).with(deprecatable, solution: "do not use")
    end
  end

  context "deprecated class has an initializer" do
    let(:deprecatable) {
      super().tap do |deprecatable|
        deprecatable.class_eval do
          attr_reader :args, :kwargs, :block

          def initialize(*args, **kwargs, &block)
            @args, @kwargs, @block = args, kwargs, block
          end
        end
      end
    }

    context "class is initialized" do
      let!(:instance) {
        deprecatable.new(:foo, :bar, baz: :qux) do
          :test
        end
      }

      it "reports the deprecation" do
        expect(Pakyow::Support::Deprecator.global).to have_received(:deprecated).with(deprecatable, solution: "do not use")
      end

      it "calls the original initializer" do
        expect(instance.args).to eq([:foo, :bar])
        expect(instance.kwargs).to eq(baz: :qux)
        expect(instance.block.call).to eq(:test)
      end
    end
  end

  context "solution is specified" do
    before do
      deprecatable.class_eval do
        deprecate solution: "use something else"
      end
    end

    context "class is initialized" do
      before do
        deprecatable.new
      end

      it "reports the deprecation" do
        expect(Pakyow::Support::Deprecator.global).to have_received(:deprecated).with(deprecatable, solution: "use something else")
      end
    end
  end

  context "solution is specified with quotes" do
    before do
      deprecatable.class_eval do
        deprecate solution: 'use "foo"'
      end
    end

    context "class is initialized" do
      before do
        deprecatable.new
      end

      it "reports the deprecation" do
        expect(Pakyow::Support::Deprecator.global).to have_received(:deprecated).with(deprecatable, solution: 'use "foo"')
      end
    end
  end
end
