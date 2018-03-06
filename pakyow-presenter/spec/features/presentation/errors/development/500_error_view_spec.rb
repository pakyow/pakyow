RSpec.describe "telling the user about a failure in development" do
  include_context "testable app"

  let :mode do
    :development
  end

  context "error is a pakyow error" do
    let :app_definition do
      Proc.new {
        instance_exec(&$presenter_app_boilerplate)

        controller do
          default do
            raise Pakyow::Error.new("failed in some way")
          end
        end
      }
    end

    it "responds 500" do
      expect(call[0]).to eq(500)
    end

    it "includes the error name" do
      expect(call[2].body.read).to include("Pakyow::Error")
    end

    it "includes the message" do
      expect(call[2].body.read).to include("failed in some way")
    end

    it "includes the backtrace" do
      expect(call[2].body.read).to include("spec/features/presentation/errors/development/500_error_view_spec.rb:15:block")
    end

    it "includes the details" do
      expect(call[2].body.read).to include("<p><code>Pakyow::Error</code> occurred on line <code>15</code>")
      expect(call[2].body.read).to include("spec/features/presentation/errors/development/500_error_view_spec.rb")
    end

    it "includes the source" do
      expect(call[2].body.read).to include("15|&gt;             raise Pakyow::Error.new(\"failed in some way\")")
    end

    it "includes a link to the docs" do
      expect(call[2].body.read).to include("https://pakyow.com/docs")
    end
  end

  context "error is not a pakyow error" do
    let :app_definition do
      Proc.new {
        instance_exec(&$presenter_app_boilerplate)

        controller do
          default do
            fail "failed in some way"
          end
        end
      }
    end

    it "responds 500" do
      expect(call[0]).to eq(500)
    end

    it "includes the error name" do
      expect(call[2].body.read).to include("RuntimeError")
    end

    it "includes the message" do
      expect(call[2].body.read).to include("failed in some way")
    end

    it "includes the backtrace" do
      expect(call[2].body.read).to include("/Users/bryanp/src/pakyow/pakyow/pakyow-presenter/spec/features/presentation/errors/development/500_error_view_spec.rb:58:in `block")
    end
  end
end
