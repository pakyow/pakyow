require "pakyow/support/core_refinements/array/ensurable"

RSpec.describe Pakyow::Support::Refinements::Array::Ensurable do
  using Pakyow::Support::Refinements::Array::Ensurable

  describe ".ensure" do
    it "ensures an array" do
      expect(Array.ensure([:foo])). to eq([:foo])
    end

    it "ensures a hash" do
      expect(Array.ensure([{ foo: :bar }])). to eq([{ foo: :bar }])
    end

    it "ensures an object" do
      object = Object.new
      expect(Array.ensure(object)). to eq([object])
    end
  end
end
