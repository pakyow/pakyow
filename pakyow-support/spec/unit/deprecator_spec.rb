require "pakyow/support/deprecator"

RSpec.describe Pakyow::Support::Deprecator do
  describe "::global" do
    let(:global) {
      described_class.global
    }

    after do
      if described_class.instance_variable_defined?(:@global)
        described_class.remove_instance_variable(:@global)
      end
    end

    it "returns a singleton" do
      expect(described_class.global).to be(global)
    end

    describe "the singleton" do
      it "is a global deprecator" do
        expect(global).to be_instance_of(described_class::Global)
      end

      it "warns" do
        require "pakyow/support/deprecator/reporters/warn"
        expect(described_class::Reporters::Warn).to receive(:report)

        global.deprecated :foo, "use `bar'"
      end

      it "does not appear to be forwarding" do
        expect(global.forwarding?).to be(false)
      end
    end

    describe "routing to other instances" do
      before do
        global >> deprecator_1
        global >> deprecator_2
        global >> deprecator_3
      end

      let(:deprecator_1) {
        double("deprecator 1", deprecated: nil)
      }

      let(:deprecator_2) {
        double("deprecator 2", deprecated: nil)
      }

      let(:deprecator_3) {
        double("deprecator 3", deprecated: nil)
      }

      let(:deprecators) {
        [
          deprecator_1,
          deprecator_2,
          deprecator_3,
        ]
      }

      it "reports to the other instances" do
        deprecators.each do |deprecator|
          expect(deprecator).to receive(:deprecated).with(:foo, "use `bar'")
        end

        global.deprecated :foo, "use `bar'"
      end

      it "does not report to its own reporter" do
        require "pakyow/support/deprecator/reporters/warn"
        expect(described_class::Reporters::Warn).not_to receive(:report)

        global.deprecated :foo, "use `bar'"
      end

      it "appears to be forwarding" do
        expect(global.forwarding?).to be(true)
      end
    end
  end

  describe "#deprecated" do
    let(:instance) {
      described_class.new(reporter: reporter)
    }

    let(:reporter) {
      double("reporter", report: nil)
    }

    it "does not build a deprecation" do
      expect(Pakyow::Support::Deprecation).not_to receive(:new)
      instance.deprecated :foo, "use `bar'"
    end

    context "reporter yields" do
      before do
        allow(reporter).to receive(:report).and_yield
      end

      it "returns a deprecation" do
        expect(
          Pakyow::Support::Deprecation
        ).to receive(:new).with(:foo, solution: "use `bar'")

        instance.deprecated(:foo, "use `bar'")
      end
    end
  end
end
