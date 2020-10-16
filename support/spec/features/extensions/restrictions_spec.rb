require "pakyow/support/extension"

RSpec.describe "restricting dependencies to a type" do
  let(:extension) {
    local = self

    Module.new {
      extend Pakyow::Support::Extension

      restrict_extension local.type
    }
  }

  let(:type) {
    Class.new.tap do |type|
      stub_const "RestrictedType", type
    end
  }

  context "including the extension into the type" do
    it "does not fail" do
      expect {
        type.include extension
      }.not_to raise_error
    end
  end

  context "including the extension into a subclass of the type" do
    it "does not fail" do
      expect {
        Class.new(type).include extension
      }.not_to raise_error
    end
  end

  context "including the extension into a different type" do
    let(:other_type) {
      Class.new.tap do |type|
        stub_const "OtherType", type
      end
    }

    it "raises a runtime error" do
      expect {
        other_type.include extension
      }.to raise_error(RuntimeError) do |error|
        expect(error.message).to eq("expected `OtherType' to be a decendent of `RestrictedType'")
      end
    end
  end
end
