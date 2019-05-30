RSpec.describe "telling the user about a failure in development" do
  include_context "app"

  let :mode do
    :development
  end

  let :allow_request_failures do
    true
  end

  context "error is a pakyow error" do
    let :app_init do
      Proc.new do
        controller do
          default do
            fail "something went wrong"
          end
        end
      end
    end

    it "responds 500" do
      expect(call[0]).to eq(500)
    end

    it "includes the error name" do
      expect(call[2]).to include("RuntimeError")
    end

    it "includes the message" do
      expect(call[2]).to include("something went wrong")
    end

    it "includes the backtrace" do
      expect(call[2]).to include("spec/features/errors/development/500_error_view_spec.rb:17:in `block (6 levels) in &lt;top (required)&gt;&#39;")
    end

    it "includes the details" do
      expect(call[2]).to include("<p><code>RuntimeError</code> occurred on line <code>17</code>")
      expect(call[2]).to include("spec/features/errors/development/500_error_view_spec.rb")
    end

    it "includes the source" do
      expect(call[2]).to include("17|›             fail &quot;something went wrong&quot;")
    end
  end

  context "error is not a pakyow error" do
    let :app_init do
      Proc.new do
        controller do
          default do
            fail "failed in some way"
          end
        end
      end
    end

    it "responds 500" do
      expect(call[0]).to eq(500)
    end

    it "includes the error name" do
      expect(call[2]).to include("RuntimeError")
    end

    it "includes the message" do
      expect(call[2]).to include("failed in some way")
    end

    it "includes the backtrace" do
      expect(call[2]).to include("spec/features/errors/development/500_error_view_spec.rb:54:in `block (6 levels) in &lt;top (required)&gt;&#39;")
    end
  end
end
