RSpec.describe "external scripts" do
  include_context "testable app"

  after do
    if File.exist?("./spec/features/tmp")
      FileUtils.rm_r("./spec/features/tmp")
    end
  end

  context "fetch is enabled" do
    let :app_definition do
      Proc.new do
        instance_exec(&$assets_app_boilerplate)

        configure :test do
          config.presenter.path = "./spec/features/tmp/frontend"

          config.assets.externals.fetch = true
          config.assets.externals.pakyow = false
          config.assets.externals.scripts = []
        end

        after :configure do
          external_script :pakyow, "1.0.0-alpha.4", package: "@pakyow/js"
          external_script :jquery, "3.3.1"
        end

        before :initialize do
          @original_stdout = $stdout
          @original_stderr = $stderr
          $stdout = $stderr = StringIO.new
        end

        after :boot do
          $stdout = @original_stdout
          $stderr = @original_stderr
        end
      end
    end

    it "downloads the specified version of each external script" do
      expect(File.exist?(File.join("./spec/features/tmp/frontend/assets/packs/vendor", "pakyow@1.0.0-alpha.4.js"))).to be(true)
      expect(File.exist?(File.join("./spec/features/tmp/frontend/assets/packs/vendor", "jquery@3.3.1.js"))).to be(true)
    end

    context "external exists" do
      let :app_definition do
        Proc.new do
          instance_exec(&$assets_app_boilerplate)

          configure :test do
            config.presenter.path = "./spec/features/tmp/frontend"

            config.assets.externals.fetch = true
            config.assets.externals.pakyow = false
            config.assets.externals.scripts = []
          end

          after :configure do
            FileUtils.mkdir_p(config.assets.externals.asset_packs_path)
            FileUtils.touch(File.join(config.assets.externals.asset_packs_path, "pakyow@1.0.0-alpha.4.js"))
            FileUtils.touch(File.join(config.assets.externals.asset_packs_path, "jquery@3.3.1.js"))
            external_script :pakyow, "1.0.0-alpha.4", package: "@pakyow/js"
            external_script :jquery, "3.3.1"
          end
        end
      end

      it "does not download again" do
        expect(File.size(File.join("./spec/features/tmp/frontend/assets/packs/vendor", "pakyow@1.0.0-alpha.4.js"))).to eq(0)
        expect(File.size(File.join("./spec/features/tmp/frontend/assets/packs/vendor", "jquery@3.3.1.js"))).to eq(0)
      end
    end

    context "external exists but it's a different version" do
      let :app_definition do
        Proc.new do
          instance_exec(&$assets_app_boilerplate)

          configure :test do
            config.presenter.path = "./spec/features/tmp/frontend"

            config.assets.externals.fetch = true
            config.assets.externals.pakyow = false
            config.assets.externals.scripts = []
          end

          after :configure do
            FileUtils.mkdir_p(config.assets.externals.asset_packs_path)
            FileUtils.touch(File.join(config.assets.externals.asset_packs_path, "pakyow@1.0.0-alpha.3.js"))
            FileUtils.touch(File.join(config.assets.externals.asset_packs_path, "jquery@3.2.1.js"))
            external_script :pakyow, "1.0.0-alpha.4", package: "@pakyow/js"
            external_script :jquery, "3.3.1"
          end
        end
      end

      it "does not download again" do
        expect(File.size(File.join("./spec/features/tmp/frontend/assets/packs/vendor", "pakyow@1.0.0-alpha.3.js"))).to eq(0)
        expect(File.exist?(File.join("./spec/features/tmp/frontend/assets/packs/vendor", "pakyow@1.0.0-alpha.4.js"))).to be(false)
        expect(File.size(File.join("./spec/features/tmp/frontend/assets/packs/vendor", "jquery@3.2.1.js"))).to eq(0)
        expect(File.exist?(File.join("./spec/features/tmp/frontend/assets/packs/vendor", "jquery@3.3.1.js"))).to be(false)
      end
    end

    context "pakyow is enabled" do
      let :app_definition do
        Proc.new do
          instance_exec(&$assets_app_boilerplate)

          configure :test do
            config.presenter.path = "./spec/features/tmp/frontend"

            config.assets.externals.fetch = true
            config.assets.externals.pakyow = true
          end
        end
      end

      it "downloads the latest pakyow" do
        latest = File.read("../pakyow-js/src/version.js").split('"', 2)[1].split('";', 2)[0]
        expect(File.exist?(File.join("./spec/features/tmp/frontend/assets/packs/vendor", "pakyow@#{latest}.js"))).to be(true)
      end
    end

    context "version is unspecified" do
      let :app_definition do
        Proc.new do
          instance_exec(&$assets_app_boilerplate)

          configure :test do
            config.presenter.path = "./spec/features/tmp/frontend"

            config.assets.externals.fetch = true
            config.assets.externals.pakyow = false
            config.assets.externals.scripts = []
          end

          after :configure do
            external_script :pakyow, package: "@pakyow/js"
          end
        end
      end

      it "downloads the latest version" do
        latest = File.read("../pakyow-js/src/version.js").split('"', 2)[1].split('";', 2)[0]
        expect(File.exist?(File.join("./spec/features/tmp/frontend/assets/packs/vendor", "pakyow@#{latest}.js"))).to be(true)
      end
    end
  end

  context "fetch is disabled" do
    let :app_definition do
      Proc.new do
        instance_exec(&$assets_app_boilerplate)

        configure :test do
          config.presenter.path = "./spec/features/tmp/frontend"

          config.assets.externals.fetch = false
          config.assets.externals.pakyow = true
        end
      end
    end

    it "does not download" do
      latest = File.read("../pakyow-js/src/version.js").split('"', 2)[1].split('";', 2)[0]
      expect(File.exist?(File.join("./spec/features/tmp/frontend/assets/packs/vendor", "pakyow@#{latest}.js"))).to be(false)
    end
  end
end
