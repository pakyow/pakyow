RSpec.describe "404 error views in development" do
  include_context "testable app"

  let :mode do
    :development
  end

  context "app explicitly triggers a 404" do
    let :app_definition do
      Proc.new {
        instance_exec(&$presenter_app_boilerplate)

        controller do
          get "/missing" do
            trigger :not_found
          end
        end
      }
    end

    it "renders the 404 page" do
      expect(call("/missing")[0]).to eq(404)
      expect(call("/missing")[2].body.read).to include("404 (Not Found)")
    end
  end
end
