RSpec.describe "environment initializers" do
  include_context "app"

  let :autorun do
    false
  end

  before do
    Pakyow.config.root = File.expand_path("../support", __FILE__)

    setup_and_run(env: :test)
  end

  it "loads each initializer" do
    expect(Pakyow).to respond_to(:foo)
    expect(Pakyow).to respond_to(:bar)
  end
end
