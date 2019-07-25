RSpec.shared_examples :default_structure do
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
        expect(File.read(File.join(generated_path, ".env"))).to match(/^SECRET=[a-zA-Z0-9]{128}$/)
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

      it "contains initializers" do
        expect(File.exist?(File.join(generated_path, "config/initializers"))).to be(true)
      end

      describe "application.rb" do
        it "sets the project name" do
          expect(File.read(File.join(generated_path, "config/application.rb"))).to include("Pakyow.app :app_test")
        end
      end

      describe "initializers" do
        it "contains application" do
          expect(File.exist?(File.join(generated_path, "config/initializers/application"))).to be(true)
        end

        it "contains environment" do
          expect(File.exist?(File.join(generated_path, "config/initializers/environment"))).to be(true)
        end

        describe "application" do
          it "is empty" do
            expect(Dir.glob(File.join(generated_path, "config/initializers/application/*"))).to eq([])
          end
        end

        describe "environment" do
          it "is empty" do
            expect(Dir.glob(File.join(generated_path, "config/initializers/environment/*"))).to eq([])
          end
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
