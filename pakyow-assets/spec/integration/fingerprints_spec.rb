RSpec.describe "fingerprinted asset" do
  let :config do
    app_class = Class.new(Pakyow::Application) do
      include Pakyow::Application::Config::Assets
    end

    app_class.config.assets
  end

  let :local_path do
    File.expand_path("../../support/app/frontend/assets/default.css", __FILE__)
  end

  it "fingerprints based on source" do
    asset = Pakyow::Assets::Asset.new(
      local_path: local_path,
      config: config
    )

    expect(asset.fingerprint).to eq(
      Digest::MD5.new.update(
        Digest::MD5.file(local_path).hexdigest
      ).hexdigest)
  end

  context "asset has dependencies" do
    it "creates a compound fingerprint" do
      dependency = File.expand_path("../../support/app/frontend/assets/default.css", __FILE__)

      asset = Pakyow::Assets::Asset.new(
        local_path: local_path,
        dependencies: [dependency],
        config: config
      )

      expect(asset.fingerprint).to eq(
        Digest::MD5.new.update(
          Digest::MD5.file(local_path).hexdigest
        ).update(
          Digest::MD5.file(dependency).hexdigest
        ).hexdigest)
    end
  end
end

RSpec.describe "fingerprinted pack" do
  let :config do
    app_class = Class.new(Pakyow::Application) do
      include Pakyow::Application::Config::Assets
    end

    app_class.config.assets
  end

  it "creates a compound fingerprint" do
    stylesheet = Pakyow::Assets::Asset.new(
      local_path: File.expand_path("../../support/app/frontend/assets/default.css", __FILE__),
      config: config
    )

    javascript = Pakyow::Assets::Asset.new(
      local_path: File.expand_path("../../support/app/frontend/assets/default.js", __FILE__),
      config: config
    )

    pack = Pakyow::Assets::Pack.new(:fingerprint_test, config)
    pack << stylesheet
    pack << javascript
    pack.finalize

    expect(pack.fingerprint).to eq(
      Digest::MD5.new.update(
          stylesheet.fingerprint
        ).update(
          javascript.fingerprint
        ).hexdigest)
  end
end
