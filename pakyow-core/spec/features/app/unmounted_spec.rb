RSpec.describe "unmounted applications" do
  include_context "app"

  let(:mount_app) {
    false
  }

  let(:app_def) {
    Proc.new {
      action do |connection|
        connection.body = "foo"
        connection.halt
      end
    }
  }

  before do
    app
  end

  it "can be looked up" do
    expect(Pakyow.app(:test).class).to eq(Test::Application)
  end

  it "does not receive requests" do
    expect(call("/")[0]).to eq(404)
  end
end
