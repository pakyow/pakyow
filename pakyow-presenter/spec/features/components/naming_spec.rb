RSpec.describe "naming presenters in backend components" do
  include_context "app"

  let :app_def do
    Proc.new do
      configure :test do
        config.presenter.componentize = true
      end

      component :single do
        presenter do
          render :post do
            replace(self.class.name)
          end
        end
      end
    end
  end

  it "names the component presenter predictibly" do
    expect(call("/components")[2]).to include("Test::Components::Single::Presenter")
  end
end
