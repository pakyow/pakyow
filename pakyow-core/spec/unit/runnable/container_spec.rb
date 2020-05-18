require "pakyow/runnable/container"
require "pakyow/runnable/container/strategies/forked"
require "pakyow/runnable/container/strategies/threaded"

RSpec.describe Pakyow::Runnable::Container do
  class MockStrategy
    attr_reader :calls

    def initialize
      @calls = []
    end

    def run(container)
      @calls << :run
    end

    def wait(container)
      @calls << :wait

      # Let the container restart three times, then stop. This lets us test restartable behavior
      # without letting the container run forever.
      #
      if @calls.count(:wait) == 3
        container.stop
      end
    end

    def interrupt
      @calls << :interrupt
    end

    def terminate
      @calls << :terminate
    end

    def success?
      @calls << :success

      true
    end
  end

  shared_context :child do
    let(:parent) {
      double(:parent)
    }

    let(:options) {
      super().tap do |options|
        options[:parent] = parent
      end
    }

    before do
      allow(::Process).to receive(:pid).and_return(4242)
    end
  end

  before do
    allow(Signal).to receive(:trap)
    allow(Process).to receive(:fork)
    allow(Process).to receive(:spawn)
  end

  after do
    instance.stop
  end

  let(:strategy) {
    MockStrategy.new
  }

  let(:instance) {
    @instance || container.new
  }

  let(:container) {
    described_class.make(:test)
  }

  let(:options) {
    {}
  }

  before do
    allow(Pakyow::Runnable::Container::Strategies::Forked).to receive(:new).and_return(strategy)
  end

  describe "::run" do
    let(:options) {
      { foo: "bar" }
    }

    let(:block) {
      Proc.new {
        "block"
      }
    }

    it "runs an instance with the given options, passing the block" do
      allow(container).to receive(:new).and_wrap_original do |original, *args, &block|
        @instance = original.call(*args, &block)

        expect(@instance).to receive(:run).with(**options) do |&block|
          expect(block.call).to eq("block")
        end

        @instance
      end

      container.run(**options, &block)
    end
  end

  describe "#run" do
    it "runs the strategy" do
      instance.run

      expect(strategy.calls.count(:run)).to eq(3)
    end

    it "yields self" do
      expect { |block|
        instance.run(&block)
      }.to yield_successive_args(instance, instance, instance)
    end

    it "waits on the strategy" do
      instance.run

      expect(strategy.calls.count(:wait)).to eq(3)
    end

    it "continues running until stopped" do
      instance.run

      expect(strategy.calls).to eq([:run, :wait, :run, :wait, :run, :wait, :interrupt, :success])
    end

    describe "running strategies" do
      before do
        allow(Pakyow::Runnable::Container::Strategies::Forked).to receive(:new).and_return(strategy)
        allow(Pakyow::Runnable::Container::Strategies::Threaded).to receive(:new).and_return(strategy)
      end

      it "runs the forked strategy by default" do
        instance.run

        expect(Pakyow::Runnable::Container::Strategies::Forked).to have_received(:new)
      end

      context "platform doesn't support process forks" do
        before do
          allow(Process).to receive(:respond_to?).with(:fork).and_return(false)
        end

        it "runs the threaded strategy" do
          instance.run

          expect(Pakyow::Runnable::Container::Strategies::Threaded).to have_received(:new)
        end
      end

      context "strategy is passed" do
        let(:options) {
          { strategy: :threaded }
        }

        it "runs the passed strategy" do
          instance.run(**options)

          expect(Pakyow::Runnable::Container::Strategies::Threaded).to have_received(:new)
        end
      end
    end

    describe "restarting the container" do
      before do
        allow(strategy).to receive(:wait)
        allow(strategy).to receive(:wait)
        allow(strategy).to receive(:wait).and_call_original
      end

      context "container is defined as restartable" do
        let(:container) {
          described_class.make :test, restartable: true
        }

        it "continues running until stopped" do
          instance.run

          expect(strategy.calls).to eq([:run, :wait, :run, :wait, :run, :wait, :interrupt, :success])
        end

        context "restartable option is passed as false" do
          let(:options) {
            { restartable: false }
          }

          it "only runs once" do
            instance.run(**options)

            expect(strategy.calls).to eq([:run, :wait, :interrupt, :success])
          end
        end
      end

      context "container is defined as not restartable" do
        let(:container) {
          described_class.make :test, restartable: false
        }

        it "only runs once" do
          instance.run

          expect(strategy.calls).to eq([:run, :wait, :interrupt, :success])
        end

        context "restartable option is passed as true" do
          let(:options) {
            { restartable: true }
          }

          it "only runs once" do
            instance.run(**options)

            expect(strategy.calls).to eq([:run, :wait, :interrupt, :success])
          end
        end
      end
    end

    describe "handling errors while running" do
      before do
        allow(strategy).to receive(:wait).and_raise(error)
      end

      describe "handling SignalException" do
        let(:error) {
          SignalException.new(:HUP)
        }

        context "container is top level" do
          it "does not raise" do
            expect {
              instance.run(**options)
            }.not_to raise_error
          end
        end

        context "container is not top level" do
          include_context :child

          it "raises" do
            expect {
              instance.run(**options)
            }.to raise_error(error)
          end
        end
      end

      describe "handling Interrupt" do
        let(:error) {
          ::Interrupt.new
        }

        context "container is top level" do
          it "does not raise" do
            expect {
              instance.run(**options)
            }.not_to raise_error
          end
        end

        context "container is not top level" do
          include_context :child

          it "raises" do
            expect {
              instance.run(**options)
            }.to raise_error(error)
          end
        end
      end

      describe "handling StandardError" do
        let(:error) {
          StandardError.new
        }

        context "container is top level" do
          it "raises" do
            expect {
              instance.run(**options)
            }.to raise_error(error)
          end
        end

        context "container is not top level" do
          include_context :child

          it "raises" do
            expect {
              instance.run(**options)
            }.to raise_error(error)
          end
        end
      end
    end

    describe "trapping signals" do
      describe "trapped HUP" do
        it "interrupts the strategy" do
          expect(Signal).to receive(:trap).with(:HUP) do |&block|
            expect(strategy).to receive(:interrupt)

            block.call
          end

          expect(strategy).to receive(:interrupt)

          instance.run
        end

        it "does not stop the container" do
          expect(Signal).to receive(:trap).with(:HUP) do |&block|
            block.call

            expect(strategy).to receive(:run).exactly(3).times.and_call_original
          end

          instance.run
        end
      end

      describe "trapped INT" do
        it "stops the container" do
          expect(Signal).to receive(:trap).with(:INT) do |&block|
            block.call
          rescue ::Interrupt
          ensure
            expect(strategy).not_to receive(:run)
          end

          instance.run
        end

        it "interrupts the strategy" do
          expect(Signal).to receive(:trap).with(:INT) do |&block|
            expect(strategy).to receive(:interrupt)

            block.call
          rescue ::Interrupt
          end

          instance.run
        end
      end

      describe "trapped TERM" do
        it "stops the container" do
          expect(Signal).to receive(:trap).with(:TERM) do |&block|
            block.call

            expect(strategy).not_to receive(:run)
          end

          instance.run
        end

        it "terminates the strategy" do
          expect(Signal).to receive(:trap).with(:TERM) do |&block|
            expect(strategy).to receive(:terminate)

            block.call
          end

          instance.run
        end
      end
    end

    describe "after running" do
      before do
        allow(instance).to receive(:success?).and_return(:success)
      end

      context "container is top-level" do
        before do
          allow(instance).to receive(:toplevel?).and_return(true)
        end

        it "returns the container status" do
          expect(instance.run).to eq(:success)
        end
      end
    end

    describe "running an unknown service" do
      it "fails before loading the strategy" do
        expect(container).not_to receive(:load_strategy)

        expect {
          instance.run(formation: Pakyow::Runnable::Formation.build { |formation| formation.run(:foo, 1) })
        }.to raise_error(Pakyow::UnknownService, "`foo' is not a known service in the `test' container")
      end
    end
  end

  describe "#restart" do
    context "container is running" do
      before do
        allow(strategy).to receive(:wait) do
          sleep 0.1
        end

        @thread = Thread.new {
          instance.run
        }

        sleep 0.2
      end

      after do
        @thread.kill
      end

      it "interrupts the strategy" do
        expect(strategy).to receive(:interrupt).twice

        instance.restart
      end
    end

    context "container is not running" do
      it "does not interrupt the strategy" do
        expect(strategy).not_to receive(:interrupt)

        instance.restart
      end
    end
  end

  describe "#stop" do
    context "container is running" do
      before do
        allow(strategy).to receive(:wait) do
          sleep 0.1
        end

        @thread = Thread.new {
          instance.run
        }

        sleep 0.2
      end

      after do
        @thread.kill
      end

      it "interrupts the strategy" do
        expect(strategy).to receive(:interrupt).once

        instance.stop
      end

      it "recognizes that it's stopped" do
        expect(strategy).to receive(:interrupt).once

        instance.stop
        instance.stop
      end
    end

    context "container is not running" do
      it "does not interrupt the strategy" do
        expect(strategy).not_to receive(:interrupt)

        instance.stop
      end
    end
  end

  describe "#running?" do
    context "container is running" do
      it "returns true" do
        expect(strategy).to receive(:wait).at_least(:once).and_wrap_original do |original, *args|
          expect(instance.running?).to be(true)
          original.call(*args)
        end

        instance.run
      end
    end

    context "container has run but is stopped" do
      it "returns false" do
        instance.run

        expect(instance.running?).to be(false)
      end
    end

    context "container has not been run" do
      it "returns false" do
        expect(instance.running?).to be(false)
      end
    end
  end

  describe "#success?" do
    context "container is running" do
      it "returns true" do
        expect(strategy).to receive(:wait).at_least(:once).and_wrap_original do |original, *args|
          expect(instance.running?).to be(true)
          expect(instance.success?).to be(true)
          original.call(*args)
        end

        instance.run
      end
    end

    context "container has run but is stopped" do
      before do
        allow(strategy).to receive(:success?).and_return(:success)
      end

      it "returns the strategy success status" do
        instance.run

        expect(instance.success?).to eq(:success)
      end
    end

    context "container has not been run" do
      it "returns nil" do
        expect(instance.success?).to eq(nil)
      end
    end
  end

  describe "loading a strategy" do
    let(:options) {
      { strategy: :foo }
    }

    before do
      allow(container).to receive(:require)
      allow(Pakyow::Runnable::Container::Strategies).to receive(:const_get).and_return(MockStrategy)
    end

    it "requires the strategy" do
      expect(container).to receive(:require).with("pakyow/runnable/container/strategies/foo")

      instance.run(**options)
    end

    it "initializes the strategy" do
      expect(Pakyow::Runnable::Container::Strategies).to receive(:const_get).with("Foo").and_return(MockStrategy)
      expect(MockStrategy).to receive(:new).and_call_original

      instance.run(**options)
    end

    context "strategy fails to load" do
      before do
        allow(container).to receive(:require).and_raise(error)
      end

      let(:error) {
        LoadError.new
      }

      it "raises an error" do
        expect {
          instance.run(**options)
        }.to raise_error(Pakyow::UnknownContainerStrategy, "`foo' is not a known container strategy") do |unknown_container_strategy_error|
          expect(unknown_container_strategy_error.cause).to be(error)
        end
      end
    end
  end
end
