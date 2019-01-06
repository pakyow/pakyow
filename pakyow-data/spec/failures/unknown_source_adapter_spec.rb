RSpec.describe "defining a source for an unknown adapter" do
  include_context "app"

  let :app_init do
    Proc.new do
      source :posts, adapter: :foo do; end
    end
  end

  let :allow_application_rescues do
    true
  end

  it "boots the app in rescue mode" do
    expect(Pakyow.apps.first.rescued?).to be(true)
    expect(call("/")[0]).to eq(500)
    expect(call("/")[2].join).to include("`foo' is not a known adapter")
  end
end
