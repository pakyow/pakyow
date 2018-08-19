RSpec.describe "environment initializers" do
  include_context "testable app"

  let :autorun do
    false
  end

  before do
    Pakyow.config.root = File.expand_path("../support", __FILE__)
  end

  after do
    run(env: :test)
  end

  it "loads each initializer" do
    allow(Pakyow).to receive(:require)

    expect(Pakyow).to receive(:require).with(File.join(
      Pakyow.config.root, "config/initializers/environment/bar.rb"
    ))

    expect(Pakyow).to receive(:require).with(File.join(
      Pakyow.config.root, "config/initializers/environment/foo.rb"
    ))
  end
end
