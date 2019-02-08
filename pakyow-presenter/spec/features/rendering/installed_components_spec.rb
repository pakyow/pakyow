RSpec.describe "installed components" do
  include_context "app"

  context "presenter is componentized" do
    let :app_def do
      Proc.new do
        configure :test do
          config.presenter.componentize = true
        end
      end
    end

    it "installs the navigable component on the html tag" do
      expect(call[2].read).to include('<html data-ui="navigable">')
    end

    it "installs the form component on form tags" do
      expect(call("/form")[2].read).to include('<form data-b="post" data-c="form" data-ui="form">')
    end
  end

  context "presenter is not componentized" do
    let :app_def do
      Proc.new do
        configure :test do
          config.presenter.componentize = false
        end
      end
    end

    it "does not install the navigable component" do
      expect(call[2].read).to_not include('data-ui="navigable"')
    end

    it "does not install the form component on form tags" do
      expect(call("/form")[2].read).to_not include('data-ui="form"')
    end
  end
end
