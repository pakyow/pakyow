RSpec.describe "implicitly rendering when a controller is called but does not render" do
  include_context "app"

  let :app_def do
    Proc.new do
      controller :default do
        get "/other" do; end
      end
    end
  end

  context "view exists" do
    it "automatically renders the view" do
      response = call("/other")
      expect(response[0]).to eq(200)
      expect(response[2]).to eq_sans_whitespace("<!DOCTYPE html>\n<html>\n  <head>\n    <title>default</title>\n  </head>\n\n  <body>\n    other\n\n  </body>\n</html>\n")
    end

    context "presenter is defined" do
      let :app_def do
        Proc.new do
          controller :default do
            get "/other" do; end
          end

          presenter "/other" do
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

    context "request method is head" do
      it "responds with an empty body" do
        response = call("/other", method: :head)
        expect(response[0]).to eq(200)
        expect(response[2].length).to eq(0)
      end

      it "sets the content length and content type headers to the expected value" do
        expect(call("/other", method: :head)[1]).to include("content-type" => "text/html")
      end
    end

    context "request format is not html" do
      it "returns a 404" do
        expect(call("/other.json")[0]).to eq(404)
      end
    end

    context "request format is any" do
      it "automatically renders the view" do
        response = call("/other", headers: { "accept" => "*/*" })
        expect(response[0]).to eq(200)
        expect(response[2]).to eq_sans_whitespace("<!DOCTYPE html>\n<html>\n  <head>\n    <title>default</title>\n  </head>\n\n  <body>\n    other\n\n  </body>\n</html>\n")
      end
    end
  end

  context "view does not exist" do
    let :app_def do
      Proc.new do
        controller :default do
          get "/nonexistent" do; end
        end
      end
    end

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

  context "route halts without rendering" do
    let :app_def do
      Proc.new do
        controller :default do
          get "/other" do
            send "halted"
          end
        end
      end
    end

    it "does not automatically render the view" do
      response = call("/other")
      expect(response[0]).to eq(200)
      expect(response[2]).to eq("halted")
    end
  end

  context "route reroutes" do
    let :app_def do
      Proc.new do
        controller :default do
          default do
            reroute "/other"
          end
        end
      end
    end

    it "renders the correct view" do
      response = call("/")
      expect(response[0]).to eq(200)
      expect(response[2]).to eq_sans_whitespace("<!DOCTYPE html>\n<html>\n  <head>\n    <title>default</title>\n  </head>\n\n  <body>\n    other\n\n  </body>\n</html>\n")
    end
  end
end
