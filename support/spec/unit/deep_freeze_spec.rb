require "pakyow/support/deep_freeze"

RSpec.describe Pakyow::Support::DeepFreeze do
  using Pakyow::Support::DeepFreeze

  let(:unfreezable_object) {
    unfreezable_class.new
  }

  let(:unfreezable_class) {
    Class.new do
      include Pakyow::Support::DeepFreeze
      insulate :fire

      attr_reader :fire, :water

      def initialize
        @fire = 'fire'
        @water = 'water'
      end
    end
  }

  describe "deep_freeze" do
    it "refines Object" do
      expect {
        Object.new.deep_freeze
      }.to_not raise_error
    end

    it "refines Delegator" do
      expect {
        SimpleDelegator.new({}).deep_freeze
      }.to_not raise_error
    end

    it "returns the object" do
      obj = Object.new

      expect(obj.deep_freeze.object_id).to be(obj.object_id)
    end

    it "deep freezes an Object without ivars" do
      obj = Object.new
      obj.deep_freeze

      expect(obj).to be_frozen
    end

    it "deep freezes an Object with ivars" do
      ivar_value = Object.new
      obj = Object.new
      obj.instance_variable_set(:@ivar_name, ivar_value)

      obj.deep_freeze

      expect(obj).to be_frozen
      expect(ivar_value).to be_frozen
    end

    it "deep freezes ivars" do
      objects = Array.new(5) { Object.new }
      objects.reduce do |parent, child|
        parent.instance_variable_set(:@child, child)
      end

      objects.first.deep_freeze

      objects.each do |obj|
        expect(obj).to be_frozen
      end
    end

    it "deep freezes ivars without loop" do
      objects = Array.new(5, Object.new)
      objects.reduce do |parent, child|
        parent.instance_variable_set(:@child, child)
      end

      objects.first.deep_freeze

      objects.each do |obj|
        expect(obj).to be_frozen
      end
    end

    it "deep freezes array items" do
      objects = Array.new(5) { Object.new }

      objects.deep_freeze

      objects.each do |obj|
        expect(obj).to be_frozen
      end

      expect(objects).to be_frozen
    end

    it "deep freezes hash keys values" do
      object = { one: Object.new, 'two': Object.new, Object.new => Object.new }

      object.deep_freeze

      object.each_pair do |key, value|
        expect(key).to be_frozen
        expect(value).to be_frozen
      end

      expect(object).to be_frozen
    end

    it "doesn't freeze unfreezeable" do
      unfreezable_object.deep_freeze

      expect(unfreezable_object).to be_frozen
      expect(unfreezable_object.water).to be_frozen
      expect(unfreezable_object.fire).not_to be_frozen
    end

    it "doesn't freeze objects that can't be frozen" do
      object = "foo"
      object.instance_eval("undef :freeze")
      expect { object.deep_freeze }.not_to raise_error
    end

    context "object defines itself as insulated" do
      let(:insulated_class) {
        Class.new do
          attr_reader :internal

          def initialize
            @internal = []
          end

          def insulated?
            true
          end
        end
      }

      let(:insulated_object) {
        insulated_class.new
      }

      before do
        insulated_object.deep_freeze
      end

      it "does not freeze the object" do
        expect(insulated_object.frozen?).to be(false)
      end

      it "does not freeze contained state" do
        expect(insulated_object.internal.frozen?).to be(false)
      end
    end
  end

  describe "freeze hooks" do
    let(:hooked_object) {
      hooked_class.new
    }

    let(:hooked_class) {
      local = self

      Class.new {
        include Pakyow::Support::DeepFreeze

        before :freeze do
          @self_was_frozen = frozen?
          @state_was_frozen = @state.frozen?
        end

        after :freeze do
          local.instance_variable_set(:@self_is_frozen, frozen?)
          local.instance_variable_set(:@state_is_frozen, @state.frozen?)
        end

        attr_reader :state, :self_was_frozen, :state_was_frozen

        def initialize
          @state = {}
        end
      }
    }

    before do
      hooked_object.deep_freeze
    end

    it "calls before freeze hook before freezing" do
      expect(hooked_object.self_was_frozen).to be(false)
    end

    it "calls before freeze hook before freezing internal state" do
      expect(hooked_object.state_was_frozen).to be(false)
    end

    it "calls after freeze hook after freezing internal state" do
      expect(@state_is_frozen).to be(true)
    end

    it "calls after freeze hook after freezing" do
      expect(@self_is_frozen).to be(true)
    end
  end

  describe Socket do
    let(:subject) {
      Socket.new(:INET, :STREAM)
    }

    it "is insulated" do
      expect(subject.insulated?).to be(true)
    end

    it "appears insulated" do
      expect(subject.respond_to?(:insulated?)).to be(true)
    end
  end

  describe IO do
    let(:subject) {
      IO.new(IO.sysopen("/dev/null", "w"), "w")
    }

    it "is insulated" do
      expect(subject.insulated?).to be(true)
    end

    it "appears insulated" do
      expect(subject.respond_to?(:insulated?)).to be(true)
    end
  end

  describe Thread do
    let(:subject) {
      Thread.new { sleep }
    }

    it "is insulated" do
      expect(subject.insulated?).to be(true)
    end

    it "appears insulated" do
      expect(subject.respond_to?(:insulated?)).to be(true)
    end
  end
end
