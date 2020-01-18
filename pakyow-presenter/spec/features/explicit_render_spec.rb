RSpec.describe "explicit rendering" do
  include_context "app"

  context "view exists" do
    let :app_def do
      Proc.new do
        controller :default do
          get "/" do
            render "/other"
          end
        end
      end
    end

    it "renders the view" do
      response = call("/")
      expect(response[0]).to eq(200)
      expect(response[2]).to eq_sans_whitespace("<!DOCTYPE html>\n<html>\n  <head>\n    <title>default</title>\n  </head>\n\n  <body>\n    other\n\n  </body>\n</html>\n")
    end

    context "request format is not html" do
      it "renders the view" do
        response = call("/", headers: { "accept" => "application/json" })
        expect(response[0]).to eq(200)
        expect(response[2]).to eq_sans_whitespace("<!DOCTYPE html>\n<html>\n  <head>\n    <title>default</title>\n  </head>\n\n  <body>\n    other\n\n  </body>\n</html>\n")
      end
    end
  end

  context "view does not exist" do
    let :app_def do
      Proc.new do
        handle 500 do
          res.body = "#{connection.error.class}: #{connection.error.message}"
        end
      end
    end

    let :app_def do
      Proc.new do
        controller :default do
          get "/" do
            render "/nonexistent"
          end
        end
      end
    end

    it "fails" do
      response = call("/")
      expect(response[0]).to eq(404)
      expect(response[2]).to include("Unknown page")
    end

    context "request format is not html" do
      it "returns a 404" do
        expect(call("/", headers: { "accept" => "application/json" })[0]).to eq(404)
      end
    end
  end

  context "presenter exists" do
    let :app_def do
      Proc.new do
        controller :default do
          get "/" do
            render "/other"
          end
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

    it "invokes the presenter" do
      response = call("/")
      expect(response[0]).to eq(200)
      expect(response[2]).to eq_sans_whitespace("<!DOCTYPE html>\n<html>\n  <head>\n    <title>invoked</title>\n  </head>\n\n  <body>\n    other\n\n  </body>\n</html>\n")
    end
  end

  context "rendering as" do
    let :app_def do
      Proc.new do
        controller :default do
          get "/" do
            render "/other", as: "/something"
          end
        end

        presenter "/something" do
          render node: -> {
            title
          } do
            self.html = "invoked"
          end
        end
      end
    end

    it "renders the view path and invokes the presenter" do
      response = call("/")
      expect(response[0]).to eq(200)
      expect(response[2]).to eq_sans_whitespace("<!DOCTYPE html>\n<html>\n  <head>\n    <title>invoked</title>\n  </head>\n\n  <body>\n    other\n\n  </body>\n</html>\n")
    end
  end

  context "passing a non-normalized path" do
    let :app_def do
      Proc.new do
        controller :default do
          get "/" do
            render "other", as: "something"
          end
        end

        presenter "something" do
          render node: -> {
            title
          } do
            self.html = "invoked"
          end
        end
      end
    end

    it "renders the view" do
      response = call("/")
      expect(response[0]).to eq(200)
      expect(response[2]).to eq_sans_whitespace("<!DOCTYPE html>\n<html>\n  <head>\n    <title>invoked</title>\n  </head>\n\n  <body>\n    other\n\n  </body>\n</html>\n")
    end
  end
end
