RSpec.describe "auto rendering exposures within parts of a view" do
  include_context "testable app"

  describe "exposing within containers" do
    let :app_definition do
      Proc.new {
        instance_exec(&$presenter_app_boilerplate)

        controller :default do
          get "/exposure/within/container" do
            expose :post, { title: "foo" }, within: :foo
            expose :post, { title: "bar" }, within: :main
          end
        end
      }
    end

    it "finds and presents each exposure" do
      expect(call("/exposure/within/container")[2].body.read).to eq("<!DOCTYPE html>\n<html>\n  <head>\n    <title>within</title>\n  </head>\n\n  <body>\n    <div data-b=\"post\">\n  <h1 data-b=\"title\">bar</h1>\n</div><script type=\"text/template\" data-version=\"default\" data-b=\"post\"><div data-b=\"post\">\n  <h1 data-b=\"title\">title goes here</h1>\n</div></script>\n\n\n\n\n    <section>\n      \n  <div data-b=\"post\">\n    <h2 data-b=\"title\">foo</h2>\n  </div><script type=\"text/template\" data-version=\"default\" data-b=\"post\"><div data-b=\"post\">\n    <h2 data-b=\"title\">title goes here</h2>\n  </div></script>\n\n    </section>\n  </body>\n</html>\n")
    end
  end

  describe "exposing within partials" do
    let :app_definition do
      Proc.new {
        instance_exec(&$presenter_app_boilerplate)

        controller :default do
          get "/exposure/within/partial" do
            expose :post, { title: "one" }, within: :one
            expose :post, { title: "two" }, within: :two
          end
        end
      }
    end

    it "finds and presents each exposure" do
      expect(call("/exposure/within/partial")[2].body.read).to eq("<!DOCTYPE html>\n<html>\n  <head>\n    <title>default</title>\n  </head>\n\n  <body>\n    <div data-b=\"post\">\n  one:\n  <h1 data-b=\"title\">one</h1>\n</div><script type=\"text/template\" data-version=\"default\" data-b=\"post\"><div data-b=\"post\">\n  one:\n  <h1 data-b=\"title\">title goes here</h1>\n</div></script>\n\n<div data-b=\"post\">\n  two:\n  <h1 data-b=\"title\">two</h1>\n</div><script type=\"text/template\" data-version=\"default\" data-b=\"post\"><div data-b=\"post\">\n  two:\n  <h1 data-b=\"title\">title goes here</h1>\n</div></script>\n\n\n  </body>\n</html>\n")
    end
  end

  context "exposing to a nonexistent part" do
    let :app_definition do
      Proc.new {
        instance_exec(&$presenter_app_boilerplate)

        controller :default do
          get "/exposure/within/nonexistent" do
            expose :post, { title: "one" }, within: :nonexistent
          end
        end
      }
    end

    it "falls back to the presenter" do
      expect(call("/exposure/within/nonexistent")[2].body.read).to eq("<!DOCTYPE html>\n<html>\n  <head>\n    <title>default</title>\n  </head>\n\n  <body>\n    <div data-b=\"post\">\n  <h1 data-b=\"title\">one</h1>\n</div><script type=\"text/template\" data-version=\"default\" data-b=\"post\"><div data-b=\"post\">\n  <h1 data-b=\"title\">title goes here</h1>\n</div></script>\n\n  </body>\n</html>\n")
    end
  end
end
