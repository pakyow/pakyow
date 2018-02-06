RSpec.describe "prototype nodes" do
  include_context "testable app"

  let :app_definition do
    Proc.new {
      Pakyow.config.logger.enabled = false

      instance_exec(&$presenter_app_boilerplate)

      controller :default do
        get "/prototype" do; end
      end
    }
  end

  context "running in prototype mode" do
    let :mode do
      :prototype
    end

    it "does not remove the prototype nodes" do
      expect(call("/prototype")[2].body.read).to eq("<!DOCTYPE html>\n<html>\n  <head>\n    <title>default</title>\n  </head>\n\n  <body>\n    <div>\n  foo\n</div>\n\n  </body>\n</html>\n")
    end
  end

  context "not running in prototype mode" do
    it "removes the prototype nodes" do
      expect(call("/prototype")[2].body.read).to eq("<!DOCTYPE html>\n<html>\n  <head>\n    <title>default</title>\n  </head>\n\n  <body>\n    \n\n  </body>\n</html>\n")
    end
  end
end
