require "pakyow/support/deep_freeze"

module Rack
  class Builder
  end
end

RSpec.describe Pakyow::Support::DeepFreeze do
  let :builder { 
    Rack::Builder.new
  }

  describe "deep_freeze" do
    using Pakyow::Support::DeepFreeze

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

    it "doesn't freeze unfreezeable" do
      builder.deep_freeze

      expect(builder).not_to be_frozen
    end
  end
end

