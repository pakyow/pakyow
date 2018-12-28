RSpec.describe "nodes marked for prototype" do
  include_context "app"

  let :app_definition do
    Proc.new {
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
      expect(call("/prototype")[2].body.read).to eq_sans_whitespace(
        <<~HTML
          <div>
            foo
          </div>
        HTML
      )
    end
  end

  context "not running in prototype mode" do
    it "removes the prototype nodes" do
      expect(call("/prototype")[2].body.read).to_not include_sans_whitespace(
        <<~HTML
          <div>
            foo
          </div>
        HTML
      )
    end
  end
end
