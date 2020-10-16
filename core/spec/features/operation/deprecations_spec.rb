RSpec.describe "deprecating operations" do
  include_context "app"

  let(:app_def) {
    Proc.new {
      operation :test do
        def foo; end
        deprecate :foo
      end
    }
  }

  let(:instance) {
    app.operations.test(**values)
  }

  let(:values) {
    {}
  }

  before do
    allow(Pakyow::Support::Deprecator.global).to receive(:deprecated)
  end

  it "deprecates instance methods" do
    instance.foo

    expect(Pakyow::Support::Deprecator.global).to have_received(:deprecated).with(
      instance, :foo, solution: "do not use"
    )
  end

  context "value is verified" do
    let(:app_def) {
      Proc.new {
        operation :test do
          required :foo
          deprecate :foo

          def bar; end
          deprecate :bar
        end
      }
    }

    let(:values) {
      { foo: "foo" }
    }

    it "deprecates the setter" do
      instance

      expect(Pakyow::Support::Deprecator.global).to have_received(:deprecated).at_least(:once).with(
        instance, "verified value `foo'", solution: "do not use"
      )
    end

    it "deprecates the getter" do
      instance.foo

      expect(Pakyow::Support::Deprecator.global).to have_received(:deprecated).at_least(:once).with(
        instance, "verified value `foo'", solution: "do not use"
      )
    end

    it "still deprecates instance methods" do
      instance.bar

      expect(Pakyow::Support::Deprecator.global).to have_received(:deprecated).at_least(:once).with(
        instance, :bar, solution: "do not use"
      )
    end

    context "value is a default" do
      let(:app_def) {
        Proc.new {
          operation :test do
            optional :foo, default: "foo"
            deprecate :foo
          end
        }
      }

      let(:values) {
        {}
      }

      it "does not invoke the setter" do
        instance

        expect(Pakyow::Support::Deprecator.global).not_to have_received(:deprecated)
      end
    end
  end
end
