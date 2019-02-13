RSpec.describe "implicitly rendering when a controller is called but does not render" do
  include_context "app"

  let :app_init do
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
      expect(response[2].read).to eq_sans_whitespace("<!DOCTYPE html>\n<html>\n  <head>\n    <title>default</title>\n  </head>\n\n  <body>\n    other\n\n  </body>\n</html>\n")
    end

    context "presenter is defined" do
      let :app_init do
        Proc.new do
          controller :default do
            get "/other" do; end
          end

          presenter "/other" do
            def perform
              self.title = "invoked"
            end
          end
        end
      end

      it "invokes the defined presenter" do
        response = call("/other")
        expect(response[0]).to eq(200)
        expect(response[2].read).to eq_sans_whitespace("<!DOCTYPE html>\n<html>\n  <head>\n    <title>invoked</title>\n  </head>\n\n  <body>\n    other\n\n  </body>\n</html>\n")
      end
    end

    context "exposures are defined in the controller" do
      let :app_init do
        Proc.new do
          controller :default do
            get "/exposure" do
              expose :post, { title: "foo" }
            end
          end
        end
      end

      it "finds and presents each exposure" do
        expect(call("/exposure")[2].read).to eq_sans_whitespace("<!DOCTYPE html>\n<html>\n  <head>\n    <title>default</title>\n  </head>\n\n  <body>\n    <div data-b=\"post\">\n  <h1 data-b=\"title\">foo</h1>\n</div><script type=\"text/template\" data-b=\"post\"><div data-b=\"post\">\n  <h1 data-b=\"title\">title goes here</h1>\n</div></script>\n\n  </body>\n</html>\n")
      end

      context "exposure is plural" do
        let :app_init do
          Proc.new do
            controller :default do
              get "/exposure" do
                expose :posts, [{ title: "foo" }, { title: "bar" }]
              end
            end
          end
        end

        it "finds and presents to the singular version" do
          expect(call("/exposure")[2].read).to eq_sans_whitespace("<!DOCTYPE html>\n<html>\n  <head>\n    <title>default</title>\n  </head>\n\n  <body>\n    <div data-b=\"post\">\n  <h1 data-b=\"title\">foo</h1>\n</div><div data-b=\"post\">\n  <h1 data-b=\"title\">bar</h1>\n</div><script type=\"text/template\" data-b=\"post\"><div data-b=\"post\">\n  <h1 data-b=\"title\">title goes here</h1>\n</div></script>\n\n  </body>\n</html>\n")
        end
      end

      context "exposure is channeled" do
        let :app_init do
          Proc.new do
            controller :default do
              get "/exposure/channeled" do
                expose :post, { title: "foo" }, for: :foo
                expose :post, { title: "bar" }, for: :bar
              end
            end
          end
        end

        it "finds and presents each channeled version" do
          expect(call("/exposure/channeled")[2].read).to eq_sans_whitespace("<!DOCTYPE html>\n<html>\n  <head>\n    <title>default</title>\n  </head>\n\n  <body>\n    <div data-b=\"post\" data-c=\"foo\">\n  foo\n  <h1 data-b=\"title\">foo</h1>\n</div><script type=\"text/template\" data-b=\"post\" data-c=\"foo\"><div data-b=\"post\" data-c=\"foo\">\n  foo\n  <h1 data-b=\"title\">title goes here</h1>\n</div></script>\n\n<div data-b=\"post\" data-c=\"bar\">\n  bar\n  <h1 data-b=\"title\">bar</h1>\n</div><script type=\"text/template\" data-b=\"post\" data-c=\"bar\"><div data-b=\"post\" data-c=\"bar\">\n  bar\n  <h1 data-b=\"title\">title goes here</h1>\n</div></script>\n\n  </body>\n</html>\n")
        end
      end

      context "exposure cannot be found" do
        let :app_init do
          Proc.new do
            controller :default do
              get "/exposure" do
                expose :post, { title: "foo" }
                expose :nonexistent, {}
              end
            end
          end
        end

        it "does not fail" do
          expect(call("/exposure")[2].read).to eq_sans_whitespace("<!DOCTYPE html>\n<html>\n  <head>\n    <title>default</title>\n  </head>\n\n  <body>\n    <div data-b=\"post\">\n  <h1 data-b=\"title\">foo</h1>\n</div><script type=\"text/template\" data-b=\"post\"><div data-b=\"post\">\n  <h1 data-b=\"title\">title goes here</h1>\n</div></script>\n\n  </body>\n</html>\n")
        end
      end
    end

    context "request method is head" do
      it "responds with an empty body" do
        response = call("/other", method: :head)
        expect(response[0]).to eq(200)
        expect(response[2].length).to eq(0)
      end

      it "sets the content length and content type headers to the expected value" do
        expect(call("/other", method: :head)[1]).to include("Content-Length" => 90, "Content-Type" => "text/html")
      end
    end

    context "request format is not html" do
      it "returns a 404" do
        expect(call("/other.json")[0]).to eq(404)
      end
    end
  end

  context "view does not exist" do
    let :app_init do
      Proc.new do
        controller :default do
          get "/nonexistent" do; end
        end
      end
    end

    it "renders a missing page error" do
      response = call("/nonexistent")
      expect(response[0]).to eq(404)
      expect(response[2].read).to include("Unknown page")
    end

    context "request format is not html" do
      it "returns a 404" do
        expect(call("/nonexistent.json")[0]).to eq(404)
      end
    end
  end

  context "route halts without rendering" do
    let :app_init do
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
      expect(response[2].read).to eq("halted")
    end
  end

  context "route reroutes" do
    let :app_init do
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
      expect(response[2].read).to eq_sans_whitespace("<!DOCTYPE html>\n<html>\n  <head>\n    <title>default</title>\n  </head>\n\n  <body>\n    other\n\n  </body>\n</html>\n")
    end
  end
end
