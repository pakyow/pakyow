RSpec.describe "external asset fetching service" do
  include_context "app"

  let(:autorun) {
    false
  }

  before do
    allow(Pakyow::Support::CLI::Runner).to receive(:new).and_return(runner)
    allow(runner).to receive(:run).and_yield(runner_status)
  end

  after do
    if File.exist?(tmp)
      FileUtils.rm_r(tmp)
    end
  end

  let(:runner) {
    double(:runner)
  }

  let(:runner_status) {
    double(:runner_status, succeeded: nil, failed: nil)
  }

  let(:tmp) {
    File.expand_path("../tmp", __FILE__)
  }

  def run
    setup

    Pakyow.container(:environment).service(:externals).run(config: Pakyow.config.runnable)
  end

  context "fetch is enabled" do
    let(:app_def) {
      local_tmp = tmp

      Proc.new {
        configure :test do
          config.presenter.path = File.join(local_tmp, "frontend")

          config.assets.externals.fetch = true
          config.assets.externals.pakyow = false
          config.assets.externals.scripts = []
        end

        after "configure" do
          external_script :pakyow, "1.0.0-alpha.4", package: "@pakyow/js"
          external_script :jquery, "<=3.3.1"
        end
      }
    }

    it "downloads the specified version of each external script" do
      run

      expect(File.exist?(File.join(tmp, "frontend/assets/packs/vendor", "pakyow@1.0.0-alpha.4.js"))).to be(true)
      expect(File.exist?(File.join(tmp, "frontend/assets/packs/vendor", "jquery@3.3.1.js"))).to be(true)
    end

    it "restarts" do
      expect(Pakyow).to receive(:restart)

      run
    end

    context "external exists" do
      let(:app_def) {
        local_tmp = tmp

        Proc.new {
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
        }
      }

      it "does not download again" do
        run

        expect(File.size(File.join(tmp, "frontend/assets/packs/vendor", "pakyow@1.0.0-alpha.4.js"))).to eq(0)
        expect(File.size(File.join(tmp, "frontend/assets/packs/vendor", "jquery@3.3.1.js"))).to eq(0)
      end
    end

    context "external exists but it's a different version" do
      let(:app_def) {
        local_tmp = tmp

        Proc.new {
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
        }
      }

      it "does not download again" do
        run

        expect(File.size(File.join(tmp, "frontend/assets/packs/vendor", "pakyow@1.0.0-alpha.3.js"))).to eq(0)
        expect(File.exist?(File.join(tmp, "frontend/assets/packs/vendor", "pakyow@1.0.0-alpha.4.js"))).to be(false)
        expect(File.size(File.join(tmp, "frontend/assets/packs/vendor", "jquery@3.2.1.js"))).to eq(0)
        expect(File.exist?(File.join(tmp, "frontend/assets/packs/vendor", "jquery@3.3.1.js"))).to be(false)
      end
    end

    context "pakyow is enabled" do
      let(:app_def) {
        local = self

        Proc.new {
          configure :test do
            config.presenter.path = File.join(local.tmp, "frontend")

            config.assets.externals.fetch = true
            config.assets.externals.pakyow = true
          end
        }
      }

      it "downloads the latest pakyow" do
        run

        expect(File.exist?(File.join(tmp, "frontend/assets/packs/vendor", "pakyow@#{$latest_pakyow_js}.js"))).to be(true)
      end
    end

    context "version is unspecified" do
      let(:app_def) {
        local = self

        Proc.new {
          configure :test do
            config.presenter.path = File.join(local.tmp, "frontend")

            config.assets.externals.fetch = true
            config.assets.externals.pakyow = false
            config.assets.externals.scripts = []
          end

          after "configure" do
            external_script :pakyow, package: "@pakyow/js"
          end
        }
      }

      it "downloads the latest version" do
        run

        expect(File.exist?(File.join(tmp, "frontend/assets/packs/vendor", "pakyow@#{$latest_pakyow_js}.js"))).to be(true)
      end
    end

    context "files are specified" do
      let(:app_def) {
        local_tmp = tmp

        Proc.new {
          configure :test do
            config.presenter.path = File.join(local_tmp, "frontend")

            config.assets.externals.fetch = true
            config.assets.externals.pakyow = false
            config.assets.externals.scripts = []
          end

          after "configure" do
            external_script :vue, "2.5.17", files: ["dist/vue.common.js", "dist/vue.runtime.js"]
          end
        }
      }

      it "downloads each file" do
        run

        expect(File.exist?(File.join(tmp, "frontend/assets/packs/vendor", "vue@2.5.17__vue.common.js"))).to be(true)
        expect(File.exist?(File.join(tmp, "frontend/assets/packs/vendor", "vue@2.5.17__vue.runtime.js"))).to be(true)
      end

      context "specified file is named the same as the external" do
        let(:app_def) {
          local_tmp = tmp

          Proc.new {
            configure :test do
              config.presenter.path = File.join(local_tmp, "frontend")

              config.assets.externals.fetch = true
              config.assets.externals.pakyow = false
              config.assets.externals.scripts = []
            end

            after "configure" do
              external_script :jquery, "3.3.1", files: ["dist/jquery.js"]
            end
          }
        }

        it "names the downloaded file appropriately" do
          run

          expect(File.exist?(File.join(tmp, "frontend/assets/packs/vendor", "jquery@3.3.1.js"))).to be(true)
        end
      end
    end
  end

  context "fetch is disabled" do
    let(:app_def) {
      local_tmp = tmp

      Proc.new {
        configure :test do
          config.presenter.path = File.join(local_tmp, "frontend")

          config.assets.externals.fetch = false
          config.assets.externals.pakyow = true
        end
      }
    }

    it "does not download" do
      expect(File.exist?(File.join(tmp, "frontend/assets/packs/vendor", "pakyow@#{$latest_pakyow_js}.js"))).to be(false)
    end
  end

  context "within a plugin" do
    before do
      require "pakyow/plugin"

      class TestPlugin < Pakyow::Plugin(:testable, File.join(__dir__, "support/plugin"))
        after "configure" do
          external_script :jquery, "3.3.1"
        end
      end
    end

    let(:app_def) {
      local = self

      Proc.new {
        plug :testable

        configure :test do
          config.root = File.join(__dir__, "support/app")
          config.presenter.path = File.join(local.tmp, "frontend")
          config.assets.externals.fetch = true
          config.assets.externals.pakyow = false
          config.assets.externals.scripts = []
        end
      }
    }

    it "downloads into the app's assets directory" do
      run

      expect(File.exist?(File.join(tmp, "frontend/assets/packs/vendor", "jquery@3.3.1.js"))).to be(true)
    end
  end
end
