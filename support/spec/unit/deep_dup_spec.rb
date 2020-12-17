require "pakyow/support/deep_dup"

RSpec.describe Pakyow::Support::DeepDup do
  describe "deep_dup" do
    using Pakyow::Support::DeepDup

    it "refines Object" do
      expect {
        Object.new.deep_dup
      }.to_not raise_error
    end

    it "refines Delegator" do
      expect {
        SimpleDelegator.new({}).deep_dup
      }.to_not raise_error
    end

    it "deep dupes a String" do
      str = "foo"
      expect(str.deep_dup).to_not be(str)
    end

    it "deep dupes an Array of Strings" do
      arr = ["foo"]
      expect(arr.deep_dup[0]).to_not be(arr[0])
    end

    it "deep dupes Hash key" do
      hsh = { Object.new => Object.new }
      hsh_dup = hsh.deep_dup
      expect(hsh_dup.keys[0]).to_not be(hsh.keys[0])
    end

    it "deep dupes Hash value" do
      hsh = { Object.new => Object.new }
      hsh_dup = hsh.deep_dup
      expect(hsh_dup.values[0]).to_not be(hsh.values[0])
    end
  end

  describe "undupables" do
    describe "Symbol" do
      it "is uncloneable" do
        expect(Pakyow::Support::DeepDup::UNDUPABLE).to include Symbol
      end
    end

    describe "NilClass" do
      it "is undupable" do
        expect(Pakyow::Support::DeepDup::UNDUPABLE).to include NilClass
      end
    end

    describe "TrueClass" do
      it "is undupable" do
        expect(Pakyow::Support::DeepDup::UNDUPABLE).to include TrueClass
      end
    end

    describe "FalseClass" do
      it "is undupable" do
        expect(Pakyow::Support::DeepDup::UNDUPABLE).to include FalseClass
      end
    end

    describe "Class" do
      it "is undupable" do
        expect(Pakyow::Support::DeepDup::UNDUPABLE).to include Class
      end
    end

    describe "Module" do
      it "is undupable" do
        expect(Pakyow::Support::DeepDup::UNDUPABLE).to include Module
      end
    end

    describe "Queue" do
      it "is undupable" do
        expect(Pakyow::Support::DeepDup::UNDUPABLE).to include Queue
      end
    end
  end

  describe "recursive deep dupes" do
    using Pakyow::Support::DeepDup

    let(:dupable) {
      hash = {}
      hash[:foo] = hash
    }

    it "deep dupes correctly" do
      duped = dupable.deep_dup

      expect(duped.object_id).to_not eq(dupable.object_id)
      expect(duped[:foo].object_id).to_not eq(dupable[:foo].object_id)
    end
  end
end
