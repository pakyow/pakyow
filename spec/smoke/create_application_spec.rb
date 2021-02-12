require "smoke_helper"

RSpec.describe "creating an application in an existing project", :repeatable, smoke: true do
  before do
    setup_default_application
    cli_run "create:application foo --path /foo"
    setup_created_application; boot
  end

  def setup_default_application
    # intentionally blank
  end

  def setup_created_application
    root_controller_path = project_path.join("apps/foo/backend/controllers/root.rb")
    FileUtils.mkdir_p(root_controller_path.dirname)

    File.open(root_controller_path, "w+") do |file|
      file.write <<~SOURCE
        controller do
          default do
            send "foo"
          end
        end
      SOURCE
    end
  end

  describe "the new application" do
    it "responds to a request" do
      response = http.get("http://localhost:#{port}/foo")

      expect(response.status).to eq(200)
      expect(response.body.to_s).to eq("foo")
    end

    it "has vendored assets" do
      expect(Dir.glob(project_path.join("apps/foo/frontend/assets/packs/vendor/*"))).not_to be_empty
    end
  end

  describe "relocating the default application" do
    def setup_default_application
      super

      default_application_initializer_path = project_path.join("config/initializers/application/test.rb")
      FileUtils.mkdir_p(default_application_initializer_path.dirname)

      File.open(default_application_initializer_path, "w+") do |file|
        file.write <<~SOURCE
          # intentionally blank
        SOURCE
      end

      default_application_root_controller_path = default_application_backend_path.join("controllers/root.rb")
      FileUtils.mkdir_p(default_application_root_controller_path.dirname)

      File.open(default_application_root_controller_path, "w+") do |file|
        file.write <<~SOURCE
          controller do
            default do
              send "smoke-test"
            end
          end
        SOURCE
      end
    end

    let(:default_application_backend_path) {
      project_path.join("backend")
    }

    it "relocates config" do
      expect(project_path.join("apps/smoke_test/config/application.rb").exist?).to be(true)
    end

    it "relocates initializers" do
      expect(project_path.join("apps/smoke_test/config/initializers/application/test.rb").exist?).to be(true)
    end

    it "relocates backend" do
      expect(project_path.join("apps/smoke_test/backend/controllers/root.rb").exist?).to be(true)
    end

    it "relocates frontend" do
      expect(project_path.join("apps/smoke_test/frontend/layouts/default.html").exist?).to be(true)
    end

    it "relocates assets" do
      expect(project_path.join("apps/smoke_test/frontend/assets").exist?).to be(true)
    end

    it "relocates public" do
      expect(project_path.join("apps/smoke_test/public/robots.txt").exist?).to be(true)
    end

    describe "the relocated application" do
      it "responds to a request" do
        response = http.get("http://localhost:#{port}/")

        expect(response.status).to eq(200)
        expect(response.body.to_s).to eq("smoke-test")
      end
    end

    context "non-standard paths" do
      def setup_default_application
        super

        File.open(project_path.join("config/application.rb"), "w+") do |file|
          file.write <<~SOURCE
            Pakyow.app :smoke_test do
              configure do
                config.src = File.join(config.root, "custom-backend")
                config.presenter.path = File.join(config.root, "custom-frontend")
                config.assets.path = File.join(config.presenter.path, "custom-assets")
                config.assets.public_path = File.join(config.root, "custom-public")
              end
            end
          SOURCE
        end

        FileUtils.mv(project_path.join("frontend/assets"), project_path.join("frontend/custom-assets"))
        FileUtils.mv(project_path.join("frontend"), project_path.join("custom-frontend"))
        FileUtils.mv(project_path.join("public"), project_path.join("custom-public"))
      end

      let(:default_application_backend_path) {
        project_path.join("custom-backend")
      }

      it "relocates backend" do
        expect(project_path.join("apps/smoke_test/custom-backend/controllers/root.rb").exist?).to be(true)
      end

      it "relocates frontend" do
        expect(project_path.join("apps/smoke_test/custom-frontend/layouts/default.html").exist?).to be(true)
      end

      it "relocates assets" do
        expect(project_path.join("apps/smoke_test/custom-frontend/custom-assets").exist?).to be(true)
      end

      it "relocates public" do
        expect(project_path.join("apps/smoke_test/custom-public/robots.txt").exist?).to be(true)
      end

      describe "the relocated application" do
        it "responds to a request" do
          response = http.get("http://localhost:#{port}/")

          expect(response.status).to eq(200)
          expect(response.body.to_s).to eq("smoke-test")
        end
      end
    end
  end
end

RSpec.describe "creating an application in an existing multiapp project", :repeatable, smoke: true do
  before do
    setup_default_application
    cli_run "create:application foo --path /foo"
    cli_run "create:application bar --path /bar"
    setup_created_application; boot
  end

  def setup_default_application
    # intentionally blank
  end

  def setup_created_application
    root_controller_path = project_path.join("apps/bar/backend/controllers/root.rb")
    FileUtils.mkdir_p(root_controller_path.dirname)

    File.open(root_controller_path, "w+") do |file|
      file.write <<~SOURCE
        controller do
          default do
            send "bar"
          end
        end
      SOURCE
    end
  end

  describe "the new application" do
    it "responds to a request" do
      response = http.get("http://localhost:#{port}/bar")

      expect(response.status).to eq(200)
      expect(response.body.to_s).to eq("bar")
    end
  end
end
