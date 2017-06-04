require "pakyow/support/deep_freeze"

using Pakyow::Support::DeepFreeze

class MyObject
  unfreezable :fire

  attr_reader :fire, :water

  def initialize
    @fire = 'fire'
    @water = 'water'
  end
end

RSpec.describe Pakyow::Support::DeepFreeze do
  let :obj_with_unfreezable { 
    MyObject.new
  }

  describe "deep_freeze" do
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

    it "returns an array of unfreezeable ivars" do
      vars = MyObject.unfreezable_variables

      expect(vars).to be_instance_of(Array)
    end
  end
end

