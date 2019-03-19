RSpec.describe "using an unknown subscribers adapter" do
  include_context "app"

  let :app_def do
    Proc.new do
      Pakyow.config.data.subscriptions.adapter = :foo
    end
  end

  let :allow_application_rescues do
    true
  end

  it "boots the app in rescue mode" do
    expect(Pakyow.apps.first.rescued?).to be(true)
    expect(call("/")[2]).to include("Failed to load subscriber adapter named `foo'")
  end
end
