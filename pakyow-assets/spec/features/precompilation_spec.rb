RSpec.describe "precompiling assets" do
  include_context "testable app"

  let :running_app do
    Pakyow.apps.first
  end

  before do
    require "pakyow/assets/precompiler"
    Pakyow::Assets::Precompiler.new(running_app).precompile!
  end

  after do
    FileUtils.rm_r(
      File.join(
        running_app.config.assets.compile_path,
        running_app.config.assets.prefix
      )
    )

    # Put back the assets that are needed for other tests.
    #
    FileUtils.mkdir_p(
      File.join(
        running_app.config.assets.compile_path,
        running_app.config.assets.prefix,
        "cache"
      )
    )
    FileUtils.touch(
      File.join(
        running_app.config.assets.compile_path,
        running_app.config.assets.prefix,
        "cache/default.css"
      )
    )
    FileUtils.mkdir_p(
      File.join(
        running_app.config.assets.compile_path,
        running_app.config.assets.prefix,
        "packs"
      )
    )
    FileUtils.touch(
      File.join(
        running_app.config.assets.compile_path,
        running_app.config.assets.prefix,
        "packs/test.css"
      )
    )
  end

  context "fingerprinting disabled" do
    let :app_definition do
      Proc.new do
        instance_exec(&$assets_app_boilerplate)
        config.assets.fingerprint = false
      end
    end

    it "precompiles assets without fingerprinting the filename" do
      expect(
        File.exist?(
          File.join(
            running_app.config.assets.compile_path,
            running_app.config.assets.prefix,
            "default.css"
          )
        )
      ).to be(true)
    end

    it "precompiles packs without fingerprinting the filename" do
      expect(
        File.exist?(
          File.join(
            running_app.config.assets.compile_path,
            running_app.config.assets.prefix,
            "packs/test.css"
          )
        )
      ).to be(true)
    end

    it "precompiles view packs without fingerprinting the filename" do
      expect(
        File.exist?(
          File.join(
            running_app.config.assets.compile_path,
            running_app.config.assets.prefix,
            "packs/layouts/view_packs.css"
          )
        )
      ).to be(true)
    end
  end

  context "fingerprinting enabled" do
    let :app_definition do
      Proc.new do
        instance_exec(&$assets_app_boilerplate)
        config.assets.fingerprint = true
      end
    end

    it "precompiles assets and fingerprints the filename" do
      expect(
        File.exist?(
          File.join(
            running_app.config.assets.compile_path,
            running_app.config.assets.prefix,
            "default__7fa5f06760d4acab98e05946e86aad82.css"
          )
        )
      ).to be(true)
    end

    it "precompiles packs and fingerprints the filename" do
      expect(
        File.exist?(
          File.join(
            running_app.config.assets.compile_path,
            running_app.config.assets.prefix,
            "packs/test__9c6c0b66d6c47154da14ad4cd741c190.css"
          )
        )
      ).to be(true)
    end

    it "precompiles view packs and fingerprints the filename" do
      expect(
        File.exist?(
          File.join(
            running_app.config.assets.compile_path,
            running_app.config.assets.prefix,
            "packs/layouts/view_packs__44717c2fcdb8f554091ee8f4762aca40.css"
          )
        )
      ).to be(true)
    end
  end
end
