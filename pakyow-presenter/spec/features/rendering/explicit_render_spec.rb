RSpec.describe "explicit rendering" do
  include_context "testable app"

  context "view exists" do
    let :app_definition do
      Proc.new {
        instance_exec(&$presenter_app_boilerplate)

        controller :default do
          get "/" do
            render "/other"
          end
        end
      }
    end

    it "renders the view" do
      response = call("/")
      expect(response[0]).to eq(200)
      expect(response[2].body.read).to eq("<!DOCTYPE html>\n<html>\n  <head>\n    <title>default</title>\n  </head>\n\n  <body>\n    other\n\n  </body>\n</html>\n")
    end
  end

  context "view does not exist" do
    let :app_definition do
      Proc.new {
        instance_exec(&$presenter_app_boilerplate)

        handle 500 do
          res.body = "#{connection.error.class}: #{connection.error.message}"
        end

        controller :default do
          get "/" do
            render "/nonexistent"
          end
        end
      }
    end

    it "fails" do
      response = call("/")
      expect(response[0]).to eq(500)
      expect(response[2].body).to include("Pakyow::Presenter::UnknownPage: Pakyow couldn't render a view for `/nonexistent`. Try creating a view template for this path:")
    end
  end

  context "overriding the layout" do
    let :app_definition do
      Proc.new {
        instance_exec(&$presenter_app_boilerplate)

        controller :default do
          get "/" do
            render "/", layout: :other
          end
        end
      }
    end

    it "uses the override" do
      response = call("/")
      expect(response[0]).to eq(200)
      expect(response[2].body.read).to eq("<!DOCTYPE html>\n<html>\n  <head>\n    <title>other</title>\n  </head>\n\n  <body>\n    index\n\n  </body>\n</html>\n")
    end

    context "layout does not exist" do
      let :app_definition do
        Proc.new {
          instance_exec(&$presenter_app_boilerplate)

          handle 500 do
            res.body = "#{connection.error.class}: #{connection.error.message}"
          end

          controller :default do
            get "/" do
              render "/", layout: :nonexistent
            end
          end
        }
      end

      it "fails" do
        response = call("/")
        expect(response[0]).to eq(500)
        expect(response[2].body).to eq("Pakyow::Presenter::UnknownLayout: Pakyow couldn't find a layout named `nonexistent`. Try creating a view template for it here:\n\n    frontend/layouts/nonexistent.html\n")
      end
    end
  end

  context "presenter exists" do
    let :app_definition do
      Proc.new {
        instance_exec(&$presenter_app_boilerplate)

        controller :default do
          get "/" do
            render "/other"
          end
        end

        presenter "/other" do
          def perform
            self.title = "invoked"
          end
        end
      }
    end

    it "invokes the presenter" do
      response = call("/")
      expect(response[0]).to eq(200)
      expect(response[2].body.read).to eq("<!DOCTYPE html>\n<html>\n  <head>\n    <title>invoked</title>\n  </head>\n\n  <body>\n    other\n\n  </body>\n</html>\n")
    end
  end

  context "rendering as" do
    let :app_definition do
      Proc.new {
        instance_exec(&$presenter_app_boilerplate)

        controller :default do
          get "/" do
            render "/other", as: "/something"
          end
        end

        presenter "/something" do
          def perform
            self.title = "invoked"
          end
        end
      }
    end

    it "renders the view path and invokes the presenter" do
      response = call("/")
      expect(response[0]).to eq(200)
      expect(response[2].body.read).to eq("<!DOCTYPE html>\n<html>\n  <head>\n    <title>invoked</title>\n  </head>\n\n  <body>\n    other\n\n  </body>\n</html>\n")
    end
  end

  context "passing a non-normalized path" do
    let :app_definition do
      Proc.new {
        instance_exec(&$presenter_app_boilerplate)

        controller :default do
          get "/" do
            render "other", as: "something"
          end
        end

        presenter "something" do
          def perform
            self.title = "invoked"
          end
        end
      }
    end

    it "renders the view" do
      response = call("/")
      expect(response[0]).to eq(200)
      expect(response[2].body.read).to eq("<!DOCTYPE html>\n<html>\n  <head>\n    <title>invoked</title>\n  </head>\n\n  <body>\n    other\n\n  </body>\n</html>\n")
    end
  end
end
