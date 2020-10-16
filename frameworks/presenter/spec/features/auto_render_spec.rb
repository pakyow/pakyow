RSpec.describe "automatically rendering when no controller is called" do
  include_context "app"

  context "view exists" do
    it "automatically renders the view" do
      response = call("/other")
      expect(response[0]).to eq(200)
      expect(response[2]).to eq_sans_whitespace("<!DOCTYPE html>\n<html>\n  <head>\n    <title>default</title>\n  </head>\n\n  <body>\n    other\n\n  </body>\n</html>\n")
    end

    context "presenter is defined" do
      let :app_def do
        Proc.new do
          presenter "/other" do
            def perform
              self.title = "invoked"
            end

            render node: -> {
              title
            } do
              self.html = "invoked"
            end
          end
        end
      end

      it "invokes the defined presenter" do
        response = call("/other")
        expect(response[0]).to eq(200)
        expect(response[2]).to eq_sans_whitespace("<!DOCTYPE html>\n<html>\n  <head>\n    <title>invoked</title>\n  </head>\n\n  <body>\n    other\n\n  </body>\n</html>\n")
      end
    end

    context "request format is not html" do
      it "returns a 404" do
        expect(call("/other.json")[0]).to eq(404)
      end
    end
  end

  context "view does not exist" do
    it "renders a missing page error" do
      response = call("/nonexistent")
      expect(response[0]).to eq(404)
      expect(response[2]).to include("Unknown page")
    end

    context "request format is not html" do
      it "returns a 404" do
        expect(call("/nonexistent.json")[0]).to eq(404)
      end
    end
  end
end
