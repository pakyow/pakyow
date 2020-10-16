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

        global.deprecated :foo, solution: "use `bar'"
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
          expect(deprecator).to receive(:deprecated).with(:foo, solution: "use `bar'")
        end

        global.deprecated :foo, solution: "use `bar'"
      end

      it "does not report to its own reporter" do
        require "pakyow/support/deprecator/reporters/warn"
        expect(described_class::Reporters::Warn).not_to receive(:report)

        global.deprecated :foo, solution: "use `bar'"
      end

      it "appears to be forwarding" do
        expect(global.forwarding?).to be(true)
      end
    end

    describe "routing to the same instance twice" do
      before do
        global >> deprecator
        global >> deprecator
        global >> deprecator
      end

      let(:deprecator) {
        double("deprecator", deprecated: nil)
      }

      it "only routes once" do
        expect(deprecator).to receive(:deprecated).with(:foo, solution: "use `bar'").exactly(:once)

        global.deprecated :foo, solution: "use `bar'"
      end
    end

    describe "ignoring deprecations" do
      before do
        global >> deprecator_1
        global >> deprecator_2
        global >> deprecator_3
      end

      let(:deprecator_1) {
        described_class.new(reporter: reporter_1)
      }

      let(:deprecator_2) {
        described_class.new(reporter: reporter_2)
      }

      let(:deprecator_3) {
        described_class.new(reporter: reporter_3)
      }

      let(:reporter_1) {
        double("reporter_1", report: nil)
      }

      let(:reporter_2) {
        double("reporter_2", report: nil)
      }

      let(:reporter_3) {
        double("reporter_3", report: nil)
      }

      let(:reporters) {
        [
          reporter_1,
          reporter_2,
          reporter_3,
        ]
      }

      let(:deprecators) {
        [
          deprecator_1,
          deprecator_2,
          deprecator_3,
        ]
      }

      it "ignores deprecations reported within the block" do
        deprecators.each_with_index do |deprecator, index|
          expect(reporters[index]).not_to receive(:report)
        end

        global.ignore do
          global.deprecated :foo, solution: "use `bar'"
        end
      end

      it "does not ignore deprecations reported after the block" do
        deprecators.each_with_index do |deprecator, index|
          expect(reporters[index]).to receive(:report).once
        end

        global.ignore do
          global.deprecated :foo, solution: "use `bar'"
        end

        global.deprecated :foo, solution: "use `bar'"
      end

      context "block fails" do
        it "does not ignore deprecations reported after the block" do
          deprecators.each_with_index do |deprecator, index|
            expect(reporters[index]).to receive(:report).once
          end

          begin
            global.ignore do
              fail
            end
          rescue
          end

          global.deprecated :foo, solution: "use `bar'"
        end
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
      instance.deprecated :foo, solution: "use `bar'"
    end

    context "reporter yields" do
      before do
        allow(reporter).to receive(:report).and_yield
      end

      it "returns a deprecation" do
        expect(
          Pakyow::Support::Deprecation
        ).to receive(:new).with(:foo, solution: "use `bar'")

        instance.deprecated(:foo, solution: "use `bar'")
      end
    end
  end

  describe "#ignore" do
    let(:instance) {
      described_class.new(reporter: reporter)
    }

    let(:reporter) {
      double("reporter", report: nil)
    }

    it "ignores deprecations reported within the block" do
      expect(reporter).not_to receive(:report)

      instance.ignore do
        instance.deprecated :foo, solution: "use `bar'"
      end
    end

    it "does not ignore deprecations reported after the block" do
      expect(reporter).to receive(:report).once

      instance.ignore do
        instance.deprecated :foo, solution: "use `bar'"
      end

      instance.deprecated :foo, solution: "use `bar'"
    end

    context "block fails" do
      it "does not ignore deprecations reported after the block" do
        expect(reporter).to receive(:report).once

        begin
          instance.ignore do
            fail
          end
        rescue
        end

        instance.deprecated :foo, solution: "use `bar'"
      end
    end

    describe "thread safety" do
      it "is threadsafe" do
        expect(reporter).to receive(:report).once

        thread1 = Thread.new do
          instance.ignore do
            sleep 0.1
          end
        end

        thread2 = Thread.new do
          instance.deprecated :foo, solution: "use `bar'"
        end

        thread2.join
        thread1.join
      end
    end
  end
end
