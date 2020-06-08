require "pakyow/support/definable"
require "pakyow/support/makeable"

RSpec.describe "defining state that extends another object" do
  let(:application) {
    application_class.definable :controller, controller
    application_class
  }

  let(:application_class) {
    Class.new.tap do |klass|
      Test.const_set(:Application, klass)
      klass.include Pakyow::Support::Definable
    end
  }

  let(:controller) {
    Class.new.tap do |klass|
      Test.const_set(:Controller, klass)
    end
  }

  let(:parent_object) {
    application.controller(:foo) {}
  }

  before do
    Object.const_set(:Test, Module.new)

    parent_object
  end

  describe "extending a definable object by name" do
    let(:extended_object) {
      application.controller(:bar, extends: :foo) {}
    }

    it "extends the object" do
      expect(extended_object.ancestors).to include(parent_object)
    end

    context "object does not exist with name" do
      let(:extended_object) {
        application.controller(:bar, extends: :missing) {}
      }

      it "raises an error" do
        expect {
          extended_object
        }.to raise_error(NameError, "cannot extend unknown object: :missing")
      end
    end
  end

  describe "extending a definable object by path" do
    let(:parent_object) {
      application.controller(:foo, :bar) {}
    }

    let(:extended_object) {
      application.controller(:bar, extends: [:foo, :bar]) {}
    }

    it "extends the object" do
      expect(extended_object.ancestors).to include(parent_object)
    end

    context "object does not exist with name" do
      let(:extended_object) {
        application.controller(:bar, extends: [:foo, :missing]) {}
      }

      it "raises an error" do
        expect {
          extended_object
        }.to raise_error(NameError, "cannot extend unknown object: [:foo, :missing]")
      end
    end

    context "part of the path does not exist with name" do
      let(:extended_object) {
        application.controller(:bar, extends: [:missing, :bar]) {}
      }

      it "raises an error" do
        expect {
          extended_object
        }.to raise_error(NameError, "cannot extend unknown object: [:missing, :bar]")
      end
    end
  end

  describe "extending an object by constant" do
    let(:parent_object) {
      Class.new {
        include Pakyow::Support::Makeable
      }
    }

    let(:extended_object) {
      application.controller(:bar, extends: parent_object) {}
    }

    it "extends the object" do
      expect(extended_object.ancestors).to include(parent_object)
    end
  end
end
