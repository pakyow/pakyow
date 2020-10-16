RSpec.describe "routing in prototype mode" do
  include_context "app"

  let :app_def do
    Pakyow.config.logger.enabled = false

    Proc.new {
      controller do
        default do
          send "called"
        end
      end
    }
  end

  let :mode do
    :prototype
  end

  it "does not call routes" do
    res = call
    expect(res[2]).not_to eq("called")
  end
end
