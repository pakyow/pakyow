require "pakyow/support/definable"
require "pakyow/support/makeable"

RSpec.describe "defining namespaced state" do
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

  let(:application_instance) {
    application.new
  }

  let(:controller) {
    Class.new.tap do |klass|
      Test.const_set(:Controller, klass)
    end
  }

  let(:namespaced_state) {
    application.controller(:foo, :bar) {}
  }

  before do
    Object.const_set(:Test, Module.new)
  end

  it "defines the state" do
    expect(namespaced_state).to be(Test::Application::Controllers::Foo::Bar)
  end

  it "finds the state" do
    namespaced_state

    expect(application.controllers.find(:foo, :bar)).to be(Test::Application::Controllers::Foo::Bar)
  end

  describe "defining top-level state with the same name as a namespace" do
    let(:top_level_state) {
      application.controller(:foo) {}
    }

    context "top-level state is defined before the namespaced state" do
      before do
        top_level_state
        namespaced_state
      end

      it "defines the top-level state" do
        expect(top_level_state).to be(Test::Application::Controllers::Foo)
      end

      it "defines the namespaced state" do
        expect(namespaced_state).to be(Test::Application::Controllers::Foo::Bar)
      end

      it "finds the top-level state" do
        expect(application.controllers.find(:foo)).to be(Test::Application::Controllers::Foo)
      end

      it "finds the namespaced state" do
        expect(application.controllers.find(:foo, :bar)).to be(Test::Application::Controllers::Foo::Bar)
      end
    end
  end

  describe "extending namespaced state" do
    before do
      application.controller(:foo, :bar) do
        def self.foo; end
      end

      application.controller(:foo, :bar) do
        def self.bar; end
      end
    end

    it "extends the state" do
      expect(namespaced_state).to respond_to(:foo)
      expect(namespaced_state).to respond_to(:bar)
    end
  end
end
