RSpec.describe "defining a source for an unknown connection" do
  include_context "app"

  let :app_init do
    Proc.new do
      source :posts, connection: :foo do; end
    end
  end

  it "boots the app in rescue mode" do
    expect(Pakyow.apps.first.rescued?).to be(true)
    expect(call("/")[0]).to eq(500)
    expect(call("/")[2].join).to include("`foo' is not a known database connection for the sql adapter")
  end
end
