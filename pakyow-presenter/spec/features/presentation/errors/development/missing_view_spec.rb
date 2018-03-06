RSpec.describe "telling the user about a missing view in development" do
  include_context "testable app"

  let :mode do
    :development
  end

  context "view was explicitly rendered" do
    let :app_definition do
      Proc.new {
        instance_exec(&$presenter_app_boilerplate)

        controller do
          default do
            render "/nonexistent"
          end
        end
      }
    end

    it "responds 500" do
      expect(call[0]).to eq(500)
    end

    it "includes instructions for creating a page" do
      expect(call[2].body.read).to include("To resolve this error, create a matching template at this path:")
      expect(call[2].body.read).to include("frontend/pages/nonexistent.html")
    end

    it "does not include instructions for defining a route" do
      expect(call[2].body.read).to_not include("If you don't intend to render a view")
    end

    it "includes a link to the docs" do
      expect(call[2].body.read).to include("https://pakyow.com/docs")
    end
  end

  context "view was implicitly rendered" do
    let :app_definition do
      Proc.new {
        instance_exec(&$presenter_app_boilerplate)
      }
    end

    it "responds 404" do
      expect(call("/nonexistent")[0]).to eq(404)
    end

    it "includes instructions for creating a page" do
      expect(call("/nonexistent")[2].body.read).to include("To resolve this error, create a matching template at this path:")
      expect(call("/nonexistent")[2].body.read).to include("frontend/pages/nonexistent.html")
    end

    it "includes instructions for defining a route" do
      expect(call("/nonexistent")[2].body.read).to include("If you don't intend to render a view")
      expect(call("/nonexistent")[2].body.read).to include("get \"/nonexistent\" do")
    end

    it "includes a link to the docs" do
      expect(call("/nonexistent")[2].body.read).to include("https://pakyow.com/docs")
    end
  end
end
