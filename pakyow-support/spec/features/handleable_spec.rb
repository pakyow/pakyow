RSpec.describe "handling events with handleable" do
  let(:handleable) {
    Class.new do
      include Pakyow::Support::Handleable
    end
  }

  let(:instance) {
    handleable.new
  }

  attr_accessor :handled

  after do
    @handled = false
  end

  context "no handler is defined" do
    it "does nothing" do
      expect {
        handleable.trigger :foo
      }.not_to raise_error
    end

    context "event is an exception" do
      let(:error) {
        RuntimeError.new
      }

      it "re-raises the exception" do
        expect {
          handleable.trigger error
        }.to raise_error do |raised_error|
          expect(raised_error).to be(error)
        end
      end
    end
  end

  context "global handler is defined" do
    before do
      local = self

      handleable.handle do
        local.handled = :global
      end

      handleable.handle :bar do
        local.handled = :bar
      end
    end

    it "handles unhandled events on the class" do
      handleable.trigger :foo

      expect(handled).to eq(:global)
    end

    it "handles unhandled events on the instance" do
      instance.trigger :foo

      expect(handled).to eq(:global)
    end

    it "handles unhandled exceptions on the class" do
      handleable.trigger RuntimeError.new

      expect(handled).to eq(:global)
    end

    it "handles unhandled exceptions on the instance" do
      instance.trigger RuntimeError.new

      expect(handled).to eq(:global)
    end
  end

  context "named handler is defined" do
    before do
      local = self

      handleable.handle :foo do
        local.handled = :foo
      end

      handleable.handle :bar do
        local.handled = :bar
      end
    end

    it "handles events on the class" do
      handleable.trigger :bar

      expect(handled).to eq(:bar)
    end

    it "handles events on the instance" do
      instance.trigger :bar

      expect(handled).to eq(:bar)
    end

    it "does not handle unrelated events" do
      handleable.trigger :baz

      expect(handled).to be(nil)
    end

    it "does not handle exceptions" do
      begin
        handleable.trigger RuntimeError.new
      rescue
      end

      expect(handled).to be(nil)
    end
  end

  context "named handler is defined for an exception" do
    before do
      local = self

      handleable.handle ArgumentError do
        local.handled = :argument_error
      end
    end

    it "handles the exception" do
      handleable.trigger ArgumentError.new

      expect(handled).to eq(:argument_error)
    end

    it "handles subclasses of the exception" do
      handleable.trigger Class.new(ArgumentError).new

      expect(handled).to eq(:argument_error)
    end

    it "does not handle unrelated exceptions" do
      begin
        handleable.trigger StandardError.new
      rescue
      end

      expect(handled).to be(nil)
    end

    it "does not handle unrelated events" do
      handleable.trigger :foo

      expect(handled).to be(nil)
    end
  end

  context "handler is added at runtime" do
    before do
      local = self

      instance.handle :bar do
        local.handled = :bar_instance
      end
    end

    it "handles events on the instance" do
      instance.trigger :bar

      expect(handled).to eq(:bar_instance)
    end

    it "does not handle events on the class" do
      handleable.trigger :bar

      expect(handled).to be(nil)
    end
  end

  context "handler is overridden at runtime" do
    before do
      local = self

      handleable.handle :foo do |event|
        local.handled = :foo_class; throw :halt
      end

      instance.handle :foo do |event|
        local.handled = :foo_instance; throw :halt
      end
    end

    it "handles events on the instance with the new handler" do
      instance.trigger :foo

      expect(handled).to eq(:foo_instance)
    end
  end

  describe "passing values to handlers" do
    before do
      local = self

      handleable.handle :foo do |event|
        local.handled = event
      end
    end

    it "receives the event" do
      handleable.trigger :foo

      expect(handled).to eq(:foo)
    end

    context "values are passed through trigger" do
      before do
        local = self

        handleable.handle :foo do |event, random: nil|
          local.handled = [event, random]; throw :halt
        end
      end

      let(:random) {
        Random.rand(100)
      }

      it "receives values passed through trigger" do
        handleable.trigger :foo, random: random

        expect(handled[0]).to eq(:foo)
        expect(handled[1]).to eq(random)
      end
    end
  end

  describe "using the handling context" do
    before do
      local = self

      handleable.handle RuntimeError do |event|
        local.handled = event
      end
    end

    it "handles through the class" do
      handleable.handling do
        raise RuntimeError, "something went wrong"
      end

      expect(handled.object).to be_instance_of(RuntimeError)
      expect(handled.message).to eq("something went wrong")
    end

    it "handles through the instance" do
      instance.handling do
        raise RuntimeError, "something went wrong"
      end

      expect(handled.object).to be_instance_of(RuntimeError)
      expect(handled.message).to eq("something went wrong")
    end

    describe "passing arguments" do
      before do
        local = self

        handleable.handle RuntimeError do |event, random: nil|
          local.handled = [event, random]; throw :halt
        end
      end

      let(:random) {
        Random.rand(100)
      }

      it "passes the arguments" do
        handleable.handling random: random do
          raise RuntimeError, "something went wrong"
        end

        expect(handled[0].object).to be_instance_of(RuntimeError)
        expect(handled[0].message).to eq("something went wrong")
        expect(handled[1]).to eq(random)
      end
    end
  end
end
