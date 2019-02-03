RSpec.describe "precompiling assets" do
  include_context "app"

  let :running_app do
    Pakyow.apps.first
  end

  let :relative_path do
    Pathname.new(File.expand_path("../../", __FILE__)).relative_path_from(Pathname.new(Dir.pwd)).to_s
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
    let :app_def do
      Proc.new do
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
    let :app_def do
      Proc.new do
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
            "packs/test__d4e9c4c20e45126a60a2ef90456223d6.css"
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

  context "source maps enabled" do
    let :app_def do
      Proc.new do
        config.assets.source_maps = true
      end
    end

    it "precompiles source maps for assets" do
      expect(
        File.exist?(
          File.join(
            running_app.config.assets.compile_path,
            running_app.config.assets.prefix,
            "default.js.map"
          )
        )
      ).to be(true)
    end

    it "precompiles source maps for packs" do
      expect(
        File.exist?(
          File.join(
            running_app.config.assets.compile_path,
            running_app.config.assets.prefix,
            "packs/test.js.map"
          )
        )
      ).to be(true)
    end

    it "precompiles source maps for view packs" do
      expect(
        File.exist?(
          File.join(
            running_app.config.assets.compile_path,
            running_app.config.assets.prefix,
            "packs/layouts/view_packs.js.map"
          )
        )
      ).to be(true)
    end

    context "fingerprinting enabled" do
      let :app_def do
        Proc.new do
          config.assets.source_maps = true
          config.assets.fingerprint = true
        end
      end

      it "precompiles source maps for assets" do
        expect(
          File.exist?(
            File.join(
              running_app.config.assets.compile_path,
              running_app.config.assets.prefix,
              "default__8fd708cc2c241ed1689b495477125fae.js.map"
            )
          )
        ).to be(true)
      end

      it "precompiles source maps for packs" do
        expect(
          File.exist?(
            File.join(
              running_app.config.assets.compile_path,
              running_app.config.assets.prefix,
              "packs/test__d4e9c4c20e45126a60a2ef90456223d6.js.map"
            )
          )
        ).to be(true)
      end

      it "precompiles source maps for view packs" do
        expect(
          File.exist?(
            File.join(
              running_app.config.assets.compile_path,
              running_app.config.assets.prefix,
              "packs/layouts/view_packs__44717c2fcdb8f554091ee8f4762aca40.js.map"
            )
          )
        ).to be(true)
      end

      it "adds the correct source mapping url to js assets" do
        expect(
          File.read(
            File.join(
              running_app.config.assets.compile_path,
              running_app.config.assets.prefix,
              "default__8fd708cc2c241ed1689b495477125fae.js"
            )
          )
        ).to include("//# sourceMappingURL=/assets/default__8fd708cc2c241ed1689b495477125fae.js.map")
      end

      xit "adds the correct source mapping url to css assets" do
        expect(
          File.read(
            File.join(
              running_app.config.assets.compile_path,
              running_app.config.assets.prefix,
              "default__7fa5f06760d4acab98e05946e86aad82.css"
            )
          )
        ).to include("//# sourceMappingURL=/assets/default__7fa5f06760d4acab98e05946e86aad82.css.map")
      end

      it "adds the correct source mapping url to packs" do
        expect(
          File.read(
            File.join(
              running_app.config.assets.compile_path,
              running_app.config.assets.prefix,
              "packs/test__d4e9c4c20e45126a60a2ef90456223d6.js"
            )
          )
        ).to include("//# sourceMappingURL=/assets/packs/test__d4e9c4c20e45126a60a2ef90456223d6.js.map")
      end

      it "adds the correct source mapping url to view packs" do
        expect(
          File.read(
            File.join(
              running_app.config.assets.compile_path,
              running_app.config.assets.prefix,
              "packs/layouts/view_packs__44717c2fcdb8f554091ee8f4762aca40.js"
            )
          )
        ).to include("//# sourceMappingURL=/assets/packs/layouts/view_packs__44717c2fcdb8f554091ee8f4762aca40.js.map")
      end

      it "precompiles the correct source map content for js assets" do
        map = JSON.parse(
          File.read(
            File.join(
              running_app.config.assets.compile_path,
              running_app.config.assets.prefix,
              "default__8fd708cc2c241ed1689b495477125fae.js.map"
            )
          )
        )

        expect(map["file"]).to eq("default__8fd708cc2c241ed1689b495477125fae.js")

        expect(map["sources"]).to eq([
          "/#{relative_path}/support/app/frontend/assets/default.js"
        ])
      end

      xit "precompiles the correct source map content for css assets" do
        map = JSON.parse(
          File.read(
            File.join(
              running_app.config.assets.compile_path,
              running_app.config.assets.prefix,
              "default__7fa5f06760d4acab98e05946e86aad82.css.map"
            )
          )
        )

        expect(map["file"]).to eq("default__7fa5f06760d4acab98e05946e86aad82.css")

        expect(map["sources"]).to eq([
          "/#{relative_path}/support/app/frontend/assets/default.css"
        ])
      end

      it "precompiles the correct source map content for packs" do
        map = JSON.parse(
          File.read(
            File.join(
              running_app.config.assets.compile_path,
              running_app.config.assets.prefix,
              "packs/test__d4e9c4c20e45126a60a2ef90456223d6.js.map"
            )
          )
        )

        expect(map["file"]).to eq("test__d4e9c4c20e45126a60a2ef90456223d6.js")

        expect(map["sources"]).to eq([
          "/#{relative_path}/support/app/frontend/assets/packs/test.js"
        ])
      end

      it "precompiles the correct source map content for view packs" do
        map = JSON.parse(
          File.read(
            File.join(
              running_app.config.assets.compile_path,
              running_app.config.assets.prefix,
              "packs/layouts/view_packs__44717c2fcdb8f554091ee8f4762aca40.js.map"
            )
          )
        )

        expect(map["file"]).to eq("view_packs__44717c2fcdb8f554091ee8f4762aca40.js")

        expect(map["sources"]).to eq([
          "/#{relative_path}/support/app/frontend/layouts/view_packs.js"
        ])
      end
    end
  end

  context "source maps disabled" do
    let :app_def do
      Proc.new do
        config.assets.source_maps = false
      end
    end

    it "does not precompile source maps for assets" do
      expect(
        File.exist?(
          File.join(
            running_app.config.assets.compile_path,
            running_app.config.assets.prefix,
            "default.js.map"
          )
        )
      ).to be(false)
    end

    it "does not precompile source maps for packs" do
      expect(
        File.exist?(
          File.join(
            running_app.config.assets.compile_path,
            running_app.config.assets.prefix,
            "packs/test.js.map"
          )
        )
      ).to be(false)
    end

    it "does not precompile source maps for view packs" do
      expect(
        File.exist?(
          File.join(
            running_app.config.assets.compile_path,
            running_app.config.assets.prefix,
            "packs/layouts/view_packs.js.map"
          )
        )
      ).to be(false)
    end
  end
end
