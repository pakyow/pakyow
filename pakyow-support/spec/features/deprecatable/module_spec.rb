require "pakyow/support/deprecatable"

RSpec.describe "deprecating a module" do
  let(:deprecatable) {
    Module.new {
      extend Pakyow::Support::Deprecatable
    }.tap do |deprecatable|
      stub_const "DeprecatableModule", deprecatable
    end
  }

  before do
    allow(Pakyow::Support::Deprecator.global).to receive(:deprecated)

    deprecatable.module_eval do
      deprecate
    end
  end

  it "does not report the deprecation immediately" do
    expect(Pakyow::Support::Deprecator.global).not_to have_received(:deprecated)
  end

  context "module is included" do
    before do
      Class.new.include deprecatable
    end

    it "reports the deprecation" do
      expect(Pakyow::Support::Deprecator.global).to have_received(:deprecated).with(deprecatable, "do not use")
    end
  end

  context "module extends a class" do
    before do
      Class.new.extend deprecatable
    end

    it "reports the deprecation" do
      expect(Pakyow::Support::Deprecator.global).to have_received(:deprecated).with(deprecatable, "do not use")
    end
  end

  context "module already has an included method" do
    let(:deprecatable) {
      local = self
      super().tap do |deprecatable|
        deprecatable.module_eval do
          def self.included(base)
            base.instance_variable_set(:@included, true)
          end
        end
      end
    }

    context "module is included" do
      before do
        klass.include deprecatable
      end

      let(:klass) {
        Class.new
      }

      it "reports the deprecation" do
        expect(Pakyow::Support::Deprecator.global).to have_received(:deprecated).with(deprecatable, "do not use")
      end

      it "calls the original included method" do
        expect(klass.instance_variable_get(:@included)).to be(true)
      end
    end
  end

  context "module already has an extended method" do
    let(:deprecatable) {
      local = self
      super().tap do |deprecatable|
        deprecatable.module_eval do
          def self.extended(base)
            base.instance_variable_set(:@extended, true)
          end
        end
      end
    }

    context "module extends a class" do
      before do
        klass.extend deprecatable
      end

      let(:klass) {
        Class.new
      }

      it "reports the deprecation" do
        expect(Pakyow::Support::Deprecator.global).to have_received(:deprecated).with(deprecatable, "do not use")
      end

      it "calls the original extended method" do
        expect(klass.instance_variable_get(:@extended)).to be(true)
      end
    end
  end
end
