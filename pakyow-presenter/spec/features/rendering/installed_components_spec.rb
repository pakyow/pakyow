RSpec.describe "installed components" do
  include_context "testable app"

  describe "navigable" do
    context "is enabled" do
      let :app_definition do
        Proc.new {
          instance_exec(&$presenter_app_boilerplate)

          configure :test do
            config.presenter.ui.navigable = true
          end
        }
      end

      it "installs the navigable component on the html tag" do
        expect(call[2].body.read).to include('<html data-ui="navigable">')
      end
    end

    context "is not enabled" do
      let :app_definition do
        Proc.new {
          instance_exec(&$presenter_app_boilerplate)

          configure :test do
            config.presenter.ui.navigable = false
          end
        }
      end

      it "does not install the navigable component" do
        expect(call[2].body.read).to_not include('data-ui="navigable"')
      end
    end
  end
end
