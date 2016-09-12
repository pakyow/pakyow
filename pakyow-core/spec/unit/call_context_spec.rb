require "spec_helper"
require "pakyow/core/call_context"

describe Pakyow::CallContext do
  it "is hookable" do
    expect(Pakyow::CallContext.ancestors).to include(Pakyow::Support::Hookable)
  end

  describe "known events" do
    describe "process" do
      it "is known" do
        expect(Pakyow::CallContext.is_known_event?(:process)).to be true
      end
    end

    describe "route" do
      it "is known" do
        expect(Pakyow::CallContext.is_known_event?(:route)).to be true
      end
    end

    describe "match" do
      it "is known" do
        expect(Pakyow::CallContext.is_known_event?(:match)).to be true
      end
    end

    describe "error" do
      it "is known" do
        expect(Pakyow::CallContext.is_known_event?(:error)).to be true
      end
    end
  end
end
