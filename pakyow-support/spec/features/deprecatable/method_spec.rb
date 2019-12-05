require "pakyow/support/deprecatable"

RSpec.describe "deprecating a method" do
  before do
    allow(Pakyow::Support::Deprecator.global).to receive(:deprecated)
  end

  context "method is an instance method" do
    let!(:deprecatable) {
      Class.new {
        extend Pakyow::Support::Deprecatable
      }.tap do |deprecatable|
        stub_const "DeprecatableClass", deprecatable

        deprecatable.class_eval do
          attr_reader :args, :kwargs, :block

          def foo(*args, **kwargs, &block)
            @args, @kwargs, @block = args, kwargs, block
          end

          deprecate :foo
        end
      end
    }

    it "does not report the deprecation immediately" do
      expect(Pakyow::Support::Deprecator.global).not_to have_received(:deprecated)
    end

    context "class is initialized" do
      let!(:instance) {
        deprecatable.new
      }

      it "does not report the deprecation" do
        expect(Pakyow::Support::Deprecator.global).not_to have_received(:deprecated)
      end

      context "method is called" do
        before do
          instance.foo(:foo, :bar, baz: :qux) do
            :test
          end
        end

        it "reports the deprecation" do
          expect(Pakyow::Support::Deprecator.global).to have_received(:deprecated).with(instance, :foo, "do not use")
        end

        it "calls the original initializer" do
          expect(instance.args).to eq([:foo, :bar])
          expect(instance.kwargs).to eq(baz: :qux)
          expect(instance.block.call).to eq(:test)
        end
      end
    end
  end

  context "method is a class method" do
    let!(:deprecatable) {
      Class.new.tap do |deprecatable|
        stub_const "DeprecatableClass", deprecatable

        deprecatable.class_eval do
          class << self
            extend Pakyow::Support::Deprecatable

            attr_reader :args, :kwargs, :block

            def foo(*args, **kwargs, &block)
              @args, @kwargs, @block = args, kwargs, block
            end

            deprecate :foo
          end
        end
      end
    }

    it "does not report the deprecation immediately" do
      expect(Pakyow::Support::Deprecator.global).not_to have_received(:deprecated)
    end

    context "method is called" do
      before do
        deprecatable.foo(:foo, :bar, baz: :qux) do
          :test
        end
      end

      it "reports the deprecation" do
        expect(Pakyow::Support::Deprecator.global).to have_received(:deprecated).with(deprecatable, :foo, "do not use")
      end

      it "calls the original initializer" do
        expect(deprecatable.args).to eq([:foo, :bar])
        expect(deprecatable.kwargs).to eq(baz: :qux)
        expect(deprecatable.block.call).to eq(:test)
      end
    end
  end

  context "method is a mixin" do
    let!(:deprecatable) {
      Module.new.tap do |deprecatable|
        stub_const "DeprecatableModule", deprecatable

        deprecatable.module_eval do
          attr_reader :args, :kwargs, :block

          def foo(*args, **kwargs, &block)
            @args, @kwargs, @block = args, kwargs, block
          end

          extend Pakyow::Support::Deprecatable
          deprecate :foo
        end
      end
    }

    it "does not report the deprecation immediately" do
      expect(Pakyow::Support::Deprecator.global).not_to have_received(:deprecated)
    end

    context "method is called" do
      before do
        instance.foo(:foo, :bar, baz: :qux) do
          :test
        end
      end

      let(:instance) {
        Class.new {
          include DeprecatableModule
        }.new
      }

      it "reports the deprecation" do
        expect(Pakyow::Support::Deprecator.global).to have_received(:deprecated).with(deprecatable, :foo, "do not use")
      end

      it "calls the original initializer" do
        expect(instance.args).to eq([:foo, :bar])
        expect(instance.kwargs).to eq(baz: :qux)
        expect(instance.block.call).to eq(:test)
      end
    end
  end

  context "method is a module function" do
    let!(:deprecatable) {
      Module.new.tap do |deprecatable|
        stub_const "DeprecatableModule", deprecatable

        deprecatable.module_eval do
          class << self
            attr_reader :args, :kwargs, :block
          end

          def foo(*args, **kwargs, &block)
            @args, @kwargs, @block = args, kwargs, block
          end
          module_function :foo

          extend Pakyow::Support::Deprecatable
          deprecate :foo
        end
      end
    }

    it "does not report the deprecation immediately" do
      expect(Pakyow::Support::Deprecator.global).not_to have_received(:deprecated)
    end

    context "method is called" do
      before do
        deprecatable.foo(:foo, :bar, baz: :qux) do
          :test
        end
      end

      it "reports the deprecation" do
        expect(Pakyow::Support::Deprecator.global).to have_received(:deprecated).with(deprecatable, :foo, "do not use")
      end

      it "calls the original initializer" do
        expect(deprecatable.args).to eq([:foo, :bar])
        expect(deprecatable.kwargs).to eq(baz: :qux)
        expect(deprecatable.block.call).to eq(:test)
      end
    end
  end

  context "method is not found" do
    it "raises an error" do
      expect {
        Class.new do
          extend Pakyow::Support::Deprecatable

          deprecate :foo
        end
      }.to raise_error(RuntimeError) do |error|
        expect(error.message).to eq("could not find method `foo' to deprecate")
      end
    end
  end
end
