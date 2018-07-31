require "pakyow/cli"

RSpec.describe "cli: projects:create" do
  include_context "testable command"

  before do
    allow_any_instance_of(Pakyow::CLI).to receive(:project_context?).and_return(false)
  end

  let :command do
    "projects:create"
  end

  describe "help" do
    it "is helpful" do
      expect(run_command(command, "-h")).to eq("\e[34;1mCreate a new project\e[0m\n\n\e[1mUSAGE\e[0m\n  $ pakyow projects:create [PATH]\n\n\e[1mARGUMENTS\e[0m\n  PATH  \e[33mWhere to create the project\e[0m\e[31m (required)\e[0m\n\n\e[1mOPTIONS\e[0m\n  -e, --env=env  \e[33mWhat environment to use\e[0m\n")
    end
  end

  describe "failure" do
    it "is helpful" do
      expect(run_command(command)).to eq("  \e[31m›\e[0m Missing required argument: path\n\n\e[1mUSAGE\e[0m\n  $ pakyow projects:create [PATH]\n\n\e[1mARGUMENTS\e[0m\n  PATH  \e[33mWhere to create the project\e[0m\e[31m (required)\e[0m\n\n\e[1mOPTIONS\e[0m\n  -e, --env=env  \e[33mWhat environment to use\e[0m\n")
    end
  end

  describe "running" do
    let :path do
      "test/app"
    end

    it "creates a project at the given path" do
      expect(File.exist?(File.join(command_dir, path))).to be(false)

      run_command(command, path) do
        expect(File.exist?(File.join(command_dir, path))).to be(true)
      end
    end

    it "tells the user what to do next" do
      expect(run_command(command, path)).to eq("\n\n\e[1mYou're all set! Go to your new project:\e[0m\n  $ cd test/app\n\n\e[1mThen boot it up:\e[0m\n  $ pakyow boot\n\n")
    end
  end

  describe "generated project" do
    let :generated_path do
      File.join(command_dir, path)
    end

    let :path do
      "test/app-test"
    end

    before do
      unless File.exist?(generated_path)
        run_command(command, path, cleanup: false)
      end
    end

    after :all do
      cleanup_after_command
    end

    describe "structure" do
      it "contains .env" do
        expect(File.exist?(File.join(generated_path, ".env"))).to be(true)
      end

      it "contains .ruby-version" do
        expect(File.exist?(File.join(generated_path, ".ruby-version"))).to be(true)
      end

      it "contains Gemfile" do
        expect(File.exist?(File.join(generated_path, "Gemfile"))).to be(true)
      end

      describe ".env" do
        it "sets the session secret" do
          expect(File.read(File.join(generated_path, ".env"))).to match(/^SESSION_SECRET=[a-zA-Z0-9]{128}$/)
        end
      end

      describe ".ruby-version" do
        it "sets the current ruby version" do
          expect(File.read(File.join(generated_path, ".ruby-version")).strip).to eq(RUBY_VERSION)
        end
      end

      it "does not contain backend" do
        expect(File.exist?(File.join(generated_path, "backend"))).to be(false)
      end

      it "contains config" do
        expect(File.exist?(File.join(generated_path, "config"))).to be(true)
      end

      it "contains database" do
        expect(File.exist?(File.join(generated_path, "database"))).to be(true)
      end

      it "contains frontend" do
        expect(File.exist?(File.join(generated_path, "frontend"))).to be(true)
      end

      it "contains public" do
        expect(File.exist?(File.join(generated_path, "public"))).to be(true)
      end

      describe "config" do
        it "contains application.rb" do
          expect(File.exist?(File.join(generated_path, "config/application.rb"))).to be(true)
        end

        it "contains environment.rb" do
          expect(File.exist?(File.join(generated_path, "config/environment.rb"))).to be(true)
        end

        it "contains puma/production.rb" do
          expect(File.exist?(File.join(generated_path, "config/puma/production.rb"))).to be(true)
        end

        describe "application.rb" do
          it "sets the project name" do
            expect(File.read(File.join(generated_path, "config/application.rb"))).to include("Pakyow.app :app_test")
          end
        end
      end

      describe "database" do
        it "is empty" do
          expect(Dir.glob(File.join(generated_path, "database/*"))).to eq([])
        end
      end

      describe "frontend" do
        it "contains assets" do
          expect(File.exist?(File.join(generated_path, "frontend/assets"))).to be(true)
        end

        it "contains includes" do
          expect(File.exist?(File.join(generated_path, "frontend/includes"))).to be(true)
        end

        it "contains layouts" do
          expect(File.exist?(File.join(generated_path, "frontend/layouts"))).to be(true)
        end

        it "contains pages" do
          expect(File.exist?(File.join(generated_path, "frontend/pages"))).to be(true)
        end

        describe "assets" do
          it "contains images" do
            expect(File.exist?(File.join(generated_path, "frontend/assets/images"))).to be(true)
          end

          it "contains packs" do
            expect(File.exist?(File.join(generated_path, "frontend/assets/packs"))).to be(true)
          end

          it "contains styles" do
            expect(File.exist?(File.join(generated_path, "frontend/assets/styles"))).to be(true)
          end

          describe "images" do
            it "is empty" do
              expect(Dir.glob(File.join(generated_path, "frontend/assets/images/*"))).to eq([])
            end
          end

          describe "packs" do
            it "is empty" do
              expect(Dir.glob(File.join(generated_path, "frontend/assets/packs/*"))).to eq([])
            end
          end

          describe "styles" do
            it "is empty" do
              expect(Dir.glob(File.join(generated_path, "frontend/assets/styles/*"))).to eq([])
            end
          end
        end

        describe "includes" do
          it "is empty" do
            expect(Dir.glob(File.join(generated_path, "frontend/includes/*"))).to eq([])
          end
        end

        describe "layouts" do
          it "contains default.html" do
            expect(File.exist?(File.join(generated_path, "frontend/layouts/default.html"))).to be(true)
          end

          describe "default.html" do
            it "sets the nice project name in the title" do
              expect(File.read(File.join(generated_path, "frontend/layouts/default.html"))).to include("<title>\n    App test\n  </title>")
            end
          end
        end

        describe "pages" do
          it "is empty" do
            expect(Dir.glob(File.join(generated_path, "frontend/pages/*"))).to eq([])
          end
        end
      end

      describe "public" do
        it "contains favicon.ico" do
          expect(File.exist?(File.join(generated_path, "public/favicon.ico"))).to be(true)
        end

        it "contains robots.txt" do
          expect(File.exist?(File.join(generated_path, "public/robots.txt"))).to be(true)
        end

        describe "robots.txt" do
          it "allows all" do
            expect(File.read(File.join(generated_path, "public/robots.txt")).strip).to eq("Allow: /")
          end
        end
      end
    end
  end
end
