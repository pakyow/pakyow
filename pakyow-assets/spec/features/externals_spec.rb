RSpec.describe "external scripts" do
  before do
    allow_any_instance_of(TTY::Spinner).to receive(:auto_spin)
    allow_any_instance_of(TTY::Spinner).to receive(:success)
    allow(FileUtils).to receive(:touch).and_call_original
  end

  include_context "app"

  let :tmp do
    File.expand_path("../tmp", __FILE__)
  end

  after do
    if File.exist?(tmp)
      FileUtils.rm_r(tmp)
    end
  end

  context "fetch is enabled" do
    let :app_def do
      local_tmp = tmp

      Proc.new do
        configure :test do
          config.presenter.path = File.join(local_tmp, "frontend")

          config.assets.externals.fetch = true
          config.assets.externals.pakyow = false
          config.assets.externals.scripts = []
        end

        after "configure" do
          external_script :pakyow, "1.0.0-alpha.4", package: "@pakyow/js"
          external_script :jquery, "3.3.1"
        end
      end
    end

    it "downloads the specified version of each external script" do
      expect(File.exist?(File.join(tmp, "frontend/assets/packs/vendor", "pakyow@1.0.0-alpha.4.js"))).to be(true)
      expect(File.exist?(File.join(tmp, "frontend/assets/packs/vendor", "jquery@3.3.1.js"))).to be(true)
    end

    it "touches .tmp/restart.txt" do
      expect(FileUtils).to have_received(:touch).with(File.expand_path("../../support/app/tmp/restart.txt", __FILE__))
    end

    context "external exists" do
      let :app_def do
        local_tmp = tmp

        Proc.new do
          configure :test do
            config.presenter.path = File.join(local_tmp, "frontend")

            config.assets.externals.fetch = true
            config.assets.externals.pakyow = false
            config.assets.externals.scripts = []
          end

          after "configure" do
            FileUtils.mkdir_p(config.assets.externals.path)
            FileUtils.touch(File.join(config.assets.externals.path, "pakyow@1.0.0-alpha.4.js"))
            FileUtils.touch(File.join(config.assets.externals.path, "jquery@3.3.1.js"))
            external_script :pakyow, "1.0.0-alpha.4", package: "@pakyow/js"
            external_script :jquery, "3.3.1"
          end
        end
      end

      it "does not download again" do
        expect(File.size(File.join(tmp, "frontend/assets/packs/vendor", "pakyow@1.0.0-alpha.4.js"))).to eq(0)
        expect(File.size(File.join(tmp, "frontend/assets/packs/vendor", "jquery@3.3.1.js"))).to eq(0)
      end
    end

    context "external exists but it's a different version" do
      let :app_def do
        local_tmp = tmp

        Proc.new do
          configure :test do
            config.presenter.path = File.join(local_tmp, "frontend")

            config.assets.externals.fetch = true
            config.assets.externals.pakyow = false
            config.assets.externals.scripts = []
          end

          after "configure" do
            FileUtils.mkdir_p(config.assets.externals.path)
            FileUtils.touch(File.join(config.assets.externals.path, "pakyow@1.0.0-alpha.3.js"))
            FileUtils.touch(File.join(config.assets.externals.path, "jquery@3.2.1.js"))
            external_script :pakyow, "1.0.0-alpha.4", package: "@pakyow/js"
            external_script :jquery, "3.3.1"
          end
        end
      end

      it "does not download again" do
        expect(File.size(File.join(tmp, "frontend/assets/packs/vendor", "pakyow@1.0.0-alpha.3.js"))).to eq(0)
        expect(File.exist?(File.join(tmp, "frontend/assets/packs/vendor", "pakyow@1.0.0-alpha.4.js"))).to be(false)
        expect(File.size(File.join(tmp, "frontend/assets/packs/vendor", "jquery@3.2.1.js"))).to eq(0)
        expect(File.exist?(File.join(tmp, "frontend/assets/packs/vendor", "jquery@3.3.1.js"))).to be(false)
      end
    end

    context "pakyow is enabled" do
      let :app_def do
        local = self

        Proc.new do
          configure :test do
            config.presenter.path = File.join(local.tmp, "frontend")

            config.assets.externals.fetch = true
            config.assets.externals.pakyow = true
          end
        end
      end

      it "downloads the latest pakyow" do
        expect(File.exist?(File.join(tmp, "frontend/assets/packs/vendor", "pakyow@#{latest_pakyow_js}.js"))).to be(true)
      end
    end

    context "version is unspecified" do
      let :app_def do
        local = self

        Proc.new do
          configure :test do
            config.presenter.path = File.join(local.tmp, "frontend")

            config.assets.externals.fetch = true
            config.assets.externals.pakyow = false
            config.assets.externals.scripts = []
          end

          after "configure" do
            external_script :pakyow, package: "@pakyow/js"
          end
        end
      end

      it "downloads the latest version" do
        expect(File.exist?(File.join(tmp, "frontend/assets/packs/vendor", "pakyow@#{latest_pakyow_js}.js"))).to be(true)
      end
    end

    context "files are specified" do
      let :app_def do
        local_tmp = tmp

        Proc.new do
          configure :test do
            config.presenter.path = File.join(local_tmp, "frontend")

            config.assets.externals.fetch = true
            config.assets.externals.pakyow = false
            config.assets.externals.scripts = []
          end

          after "configure" do
            external_script :vue, "2.5.17", files: ["dist/vue.common.js", "dist/vue.runtime.js"]
          end
        end
      end

      it "downloads each file" do
        expect(File.exist?(File.join(tmp, "frontend/assets/packs/vendor", "vue@2.5.17__vue.common.js"))).to be(true)
        expect(File.exist?(File.join(tmp, "frontend/assets/packs/vendor", "vue@2.5.17__vue.runtime.js"))).to be(true)
      end

      context "specified file is named the same as the external" do
        let :app_def do
          local_tmp = tmp

          Proc.new do
            configure :test do
              config.presenter.path = File.join(local_tmp, "frontend")

              config.assets.externals.fetch = true
              config.assets.externals.pakyow = false
              config.assets.externals.scripts = []
            end

            after "configure" do
              external_script :jquery, "3.3.1", files: ["dist/jquery.js"]
            end
          end
        end

        it "names the downloaded file appropriately" do
          expect(File.exist?(File.join(tmp, "frontend/assets/packs/vendor", "jquery@3.3.1.js"))).to be(true)
        end
      end
    end
  end

  context "fetch is disabled" do
    let :app_def do
      local_tmp = tmp

      Proc.new do
        configure :test do
          config.presenter.path = File.join(local_tmp, "frontend")

          config.assets.externals.fetch = false
          config.assets.externals.pakyow = true
        end
      end
    end

    it "does not download" do
      expect(File.exist?(File.join(tmp, "frontend/assets/packs/vendor", "pakyow@#{latest_pakyow_js}.js"))).to be(false)
    end
  end
end
