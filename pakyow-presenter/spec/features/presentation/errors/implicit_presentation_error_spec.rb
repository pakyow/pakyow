RSpec.describe "errors during implicit presentation" do
  include_context "app"

  let :app_init do
    Proc.new do
      controller do
        default do
        end
      end

      presenter "/" do
        def perform
          fail "failed in presenter"
        end
      end
    end
  end

  let :mode do
    :development
  end

  let :allow_request_failures do
    true
  end

  it "handles the error" do
    expect(call("/")[0]).to eq(500)
    expect(call("/")[2].body.read).to include("RuntimeError")
    expect(call("/")[2].body.read).to include("failed in presenter")
  end
end
