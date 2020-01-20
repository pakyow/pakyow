RSpec.describe "using helpers in a controller" do
  include_context "app"

  let :app_def do
    Proc.new {
      controller do
        default do
          send current_user
        end
      end

      helper :current_user do
        def current_user
          "current_user"
        end
      end
    }
  end

  it "can call the helper" do
    expect(call[0]).to eq(200)
    expect(call[2]).to eq("current_user")
  end
end
