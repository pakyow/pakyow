RSpec.describe "app initializers" do
  include_context "app"

  let :autorun do
    false
  end

  let :app_def do
    Proc.new do
      config.root = File.expand_path("../../support", __FILE__)
    end
  end

  before do
    Pakyow.config.root = File.expand_path("../../support", __FILE__)
  end

  after do
    setup_and_run(env: :test)
  end

  context "single app environment" do
    it "evals each initializer in context of the app" do
      allow(Pakyow::Application).to receive(:class_eval).and_call_original

      expect(Pakyow::Application).to receive(:class_eval).with(
        "\"baz\"\n",
        File.join(File.expand_path("../../support", __FILE__), "config/initializers/application/baz.rb")
      ).and_return(nil)

      expect(Pakyow::Application).to receive(:class_eval).with(
        "\"qux\"\n",
        File.join(File.expand_path("../../support", __FILE__), "config/initializers/application/qux.rb")
      ).and_return(nil)
    end
  end

  context "multi app environment" do
    it "evals each initializer in context of the app"
  end
end
