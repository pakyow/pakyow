RSpec.describe "auto rendering" do
  include_context "testable app"

  let :app_definition do
    Proc.new {
      instance_exec(&$presenter_app_boilerplate)

      controller :default do
        get "/other" do; end
      end
    }
  end

  context "view exists" do
    it "automatically renders the view" do
      response = call("/other")
      expect(response[0]).to eq(200)
      expect(response[2].body.read).to eq("<!DOCTYPE html>\n<html>\n  <head>\n    <title>default</title>\n  </head>\n\n  <body>\n    other\n\n  </body>\n</html>\n")
    end

    context "presenter is defined" do
      let :app_definition do
        Proc.new {
          instance_exec(&$presenter_app_boilerplate)

          controller :default do
            get "/other" do; end
          end

          view "/other" do
            self.title = "invoked"
          end
        }
      end

      it "invokes the presenter" do
        response = call("/other")
        expect(response[0]).to eq(200)
        expect(response[2].body.read).to eq("<!DOCTYPE html>\n<html>\n  <head>\n    <title>invoked</title>\n  </head>\n\n  <body>\n    other\n\n  </body>\n</html>\n")
      end
    end
  end

  context "view does not exist" do
    let :app_definition do
      Proc.new {
        instance_exec(&$presenter_app_boilerplate)

        controller :default do
          get "/nonexistent" do; end
        end
      }
    end

    it "does not render, or fail" do
      response = call("/nonexistent")
      expect(response[0]).to eq(200)
      expect(response[2].body).to eq([])
    end
  end
end
