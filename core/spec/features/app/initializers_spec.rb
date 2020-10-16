RSpec.describe "app initializers" do
  include_context "app"

  let :autorun do
    false
  end

  before do
    Pakyow.config.root = File.expand_path("../../support", __FILE__)
  end

  after do
    setup_and_run(env: :test)
  end

  context "single app environment" do
    it "evals each initializer in context of the app" do
      expect(app.instance_methods(false)).to include(:baz)
      expect(app.instance_methods(false)).to include(:qux)
    end
  end

  context "multi app environment" do
    it "evals each initializer in context of the app"
  end
end
