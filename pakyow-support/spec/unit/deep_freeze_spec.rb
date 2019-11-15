require "pakyow/support/deep_freeze"
using Pakyow::Support::DeepFreeze

class MyObject
  extend Pakyow::Support::DeepFreeze
  insulate :fire

  attr_reader :fire, :water

  def initialize
    @fire = 'fire'
    @water = 'water'
  end
end

RSpec.describe Pakyow::Support::DeepFreeze do
  let :obj_with_unfreezable do
    MyObject.new
  end

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
      obj_with_unfreezable.deep_freeze

      expect(obj_with_unfreezable).to be_frozen
      expect(obj_with_unfreezable.water).to be_frozen
      expect(obj_with_unfreezable.fire).not_to be_frozen
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

      it "freezes contained state" do
        expect(insulated_object.internal.frozen?).to be(true)
      end
    end
  end

  describe "::unfreezeable" do
    before do
      allow(Pakyow::Support::Deprecator.global).to receive(:deprecated)
    end

    it "is deprecated" do
      expect(
        Pakyow::Support::Deprecator.global
      ).to receive(:deprecated).with(:unfreezable, "use `insulate'")

      MyObject.unfreezable :foo
    end

    it "calls ::insulate" do
      expect(MyObject).to receive(:insulate).with(:foo)

      MyObject.unfreezable :foo
    end
  end
end
