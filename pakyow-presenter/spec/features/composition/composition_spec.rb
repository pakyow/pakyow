RSpec.describe "view template composition via presenter" do
  include_context "testable app"

  let :app_definition do
    Proc.new {
      instance_exec(&$presenter_app_boilerplate)

      handle 500 do
        res.body = "#{connection.error.class}: #{connection.error.message}"
      end

      controller :default do
        get(/.*/) do
          render connection.path
        end
      end
    }
  end

  it "composes a page into its layout" do
    response = call("/")
    expect(response[0]).to eq(200)
    expect(response[2].body.read).to eq("<!DOCTYPE html>\n<html>\n  <head>\n    <title>default</title>\n  </head>\n\n  <body>\n    index\n\n  </body>\n</html>\n")
  end

  context "page explicitly sets a layout" do
    it "uses the layout set by the page" do
      response = call("/layout")
      expect(response[0]).to eq(200)
      expect(response[2].body.read).to eq("<!DOCTYPE html>\n<html>\n  <head>\n    <title>other</title>\n  </head>\n\n  <body>\n    explicit layout\n\n  </body>\n</html>\n")
    end
  end

  context "page defines content for a container" do
    it "composes the content into the container" do
      response = call("/within")
      expect(response[0]).to eq(200)
      expect(response[2].body.read).to eq("<!DOCTYPE html>\n<html>\n  <head>\n    <title>within</title>\n  </head>\n\n  <body>\n    within\n\n\n\n\n    <section>\n      \n  this is foo\n\n    </section>\n  </body>\n</html>\n")
    end

    context "container is not defined in the layout" do
      it "ignores the page-defined content" do
        response = call("/within/default")
        expect(response[0]).to eq(200)
        expect(response[2].body.read).to eq("<!DOCTYPE html>\n<html>\n  <head>\n    <title>default</title>\n  </head>\n\n  <body>\n    within\n\n\n\n  </body>\n</html>\n")
      end
    end

    context "page content includes a partial" do
      it "includes the partial" do
        response = call("/within/page-includes-partial")
        expect(response[0]).to eq(200)
        expect(response[2].body.read).to eq("<!DOCTYPE html>\n<html>\n  <head>\n    <title>within</title>\n  </head>\n\n  <body>\n    within\n\n\n\n\n    <section>\n      \n  global\n\n\n    </section>\n  </body>\n</html>\n")
      end
    end
  end

  context "page does not define content for a container" do
    it "removes the container" do
      response = call("/within/page-provides-no-content")
      expect(response[0]).to eq(200)
      expect(response[2].body.read).to eq("<!DOCTYPE html>\n<html>\n  <head>\n    <title>within</title>\n  </head>\n\n  <body>\n    within\n\n\n    <section>\n      \n    </section>\n  </body>\n</html>\n")
    end
  end

  context "page includes a partial" do
    it "composes the partial into the page" do
      response = call("/partials")
      expect(response[0]).to eq(200)
      expect(response[2].body.read).to eq("<!DOCTYPE html>\n<html>\n  <head>\n    <title>default</title>\n  </head>\n\n  <body>\n    foo partial\n\n\n  </body>\n</html>\n")
    end

    context "partial includes a partial" do
      it "composes the partial into the partial" do
        response = call("/partials/deep")
        expect(response[0]).to eq(200)
        expect(response[2].body.read).to eq("<!DOCTYPE html>\n<html>\n  <head>\n    <title>default</title>\n  </head>\n\n  <body>\n    deep\n\nfoo partial\n\n\n\n  </body>\n</html>\n")
      end
    end

    context "partial is defined globally" do
      it "composes the partial into the page" do
        response = call("/partials/global")
        expect(response[0]).to eq(200)
        expect(response[2].body.read).to eq("<!DOCTYPE html>\n<html>\n  <head>\n    <title>default</title>\n  </head>\n\n  <body>\n    global\n\n\n  </body>\n</html>\n")
      end

      context "global partial includes a partial defined locally" do
        it "composes the global partial with the local" do
          response = call("/partials/global/local")
          expect(response[0]).to eq(200)
          expect(response[2].body.read).to eq("<!DOCTYPE html>\n<html>\n  <head>\n    <title>default</title>\n  </head>\n\n  <body>\n    local\n\n\n\n  </body>\n</html>\n")
        end
      end
    end

    context "partial is defined at a higher level" do
      it "composes the partial into the page" do
        response = call("/partials/high-level")
        expect(response[0]).to eq(200)
        expect(response[2].body.read).to eq("<!DOCTYPE html>\n<html>\n  <head>\n    <title>default</title>\n  </head>\n\n  <body>\n    foo partial\n\n\n  </body>\n</html>\n")
      end
    end

    context "partial is defined at multiple levels" do
      it "composes the most specific partial into the page" do
        response = call("/partials/high-level/override")
        expect(response[0]).to eq(200)
        expect(response[2].body.read).to eq("<!DOCTYPE html>\n<html>\n  <head>\n    <title>default</title>\n  </head>\n\n  <body>\n    foo override\n\n\n  </body>\n</html>\n")
      end
    end
  end

  context "layout includes a partial" do
    it "composes the partial into the layout" do
      response = call("/partials/layout")
      expect(response[0]).to eq(200)
      expect(response[2].body.read).to eq("<!DOCTYPE html>\n<html>\n  <head>\n    <title>partial</title>\n  </head>\n\n  <body>\n    partials/layout\n\n\n    <section>\n      foo partial\n\n    </section>\n  </body>\n</html>\n")
    end
  end

  context "index page exists" do
    it "uses the index page" do
      response = call("/default")
      expect(response[0]).to eq(200)
      expect(response[2].body.read).to eq("<!DOCTYPE html>\n<html>\n  <head>\n    <title>default</title>\n  </head>\n\n  <body>\n    default/index\n\n  </body>\n</html>\n")
    end
  end

  context "explicit render for nonexistent view" do
    it "raises a MissingPage" do
      response = call("/fail")
      expect(response[0]).to eq(500)
      expect(response[2].body).to include("Pakyow::Presenter::MissingPage: Pakyow could not find a page to render for `/fail`.")
    end
  end
end
