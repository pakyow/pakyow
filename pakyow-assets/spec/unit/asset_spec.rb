RSpec.describe Pakyow::Assets::Asset do
  let :config do
    app_class = Class.new(Pakyow::App) do
      include Pakyow::App::Config::Assets

      configurable :presenter do
        setting :path, ""
      end
    end

    app_class.config.assets
  end

  let :local_path do
    File.expand_path("../../support/app/frontend/assets/types-js.js", __FILE__)
  end

  let :instance do
    described_class.new(
      local_path: local_path,
      config: config
    )
  end

  describe "loading the content" do
    it "eagerly loads" do
      expect_any_instance_of(described_class).not_to receive(:process)
      instance
    end

    it "only loads once" do
      expect(instance).to receive(:process).once.and_call_original
      instance.read
      instance.read
    end

    it "freezes after loading" do
      expect {
        instance.read
      }.to change {
        instance.frozen?
      }.from(false).to(true)
    end
  end

  describe "setting the mime type" do
    context "known type" do
      it "sets the mime type" do
        expect(instance.mime_type).to eq("application/javascript")
      end
    end

    context "unknown type" do
      let :local_path do
        File.expand_path("../../support/app/frontend/assets/foo.bar", __FILE__)
      end

      it "does not set the mime type" do
        expect(instance.mime_type).to eq("")
      end
    end
  end
end
