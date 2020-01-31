RSpec.describe "using an operation's getters and setters" do
  include_context "app"

  let(:app_def) {
    Proc.new {
      operation :foo do
        action do
          self.foo = foo.reverse
        end
      end
    }
  }

  let(:values) {
    { foo: "foo" }
  }

  it "defines a dynamic getter and setter for each value" do
    expect(app.operations.foo(values).foo).to eq("oof")
  end

  context "setter is explicitly defined" do
    let(:app_def) {
      Proc.new {
        operation :foo do
          def foo=(value)
            @foo = value.reverse
          end

          action do
            @foo = foo.reverse
          end
        end
      }
    }

    it "invokes the setter" do
      expect(app.operations.foo(values).foo).to eq("foo")
    end
  end

  describe "real methods for verified values" do
    let(:app_def) {
      Proc.new {
        operation :foo do
          required :foo
          optional :bar
        end
      }
    }

    it "defines a real getter for required values" do
      expect(app.operations.foo(values).class.method_defined?(:foo)).to be(true)
    end

    it "defines a real getter for optional values" do
      expect(app.operations.foo(values).class.method_defined?(:bar)).to be(true)
    end

    it "privately defines a real setter for required values" do
      expect(app.operations.foo(values).class.private_method_defined?(:foo=)).to be(true)
    end

    it "privately defines a real setter for optional values" do
      expect(app.operations.foo(values).class.private_method_defined?(:bar=)).to be(true)
    end

    context "getters and setters are already defined" do
      let(:app_def) {
        Proc.new {
          operation :foo do
            def foo=(*)
              @foo = "123"
            end

            def foo
              @foo.reverse
            end

            required :foo
          end
        }
      }

      it "does not override them" do
        expect(app.operations.foo(values).foo).to eq("321")
      end
    end

    context "private getters and setters are already defined" do
      let(:app_def) {
        Proc.new {
          operation :foo do
            private def foo=(*)
              @foo = "123"
            end

            private def foo
              @foo.reverse
            end

            required :foo
          end
        }
      }

      it "does not override them" do
        expect(app.operations.foo(values).send(:foo)).to eq("321")
      end
    end
  end
end
