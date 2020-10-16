RSpec.describe "view traversal via presenter" do
  include_context "app"

  let :presenter do
    Pakyow::Presenter::Presenter.new(view, app: Pakyow.apps[0])
  end

  describe "form" do
    let :view do
      Pakyow::Presenter::View.new("<form binding=\"post\"></form>")
    end

    it "returns the form" do
      expect(presenter.form(:post)).to be_instance_of(Pakyow::Presenter::Presenters::Form)
      expect(presenter.form(:post).view).to be_instance_of(Pakyow::Presenter::Views::Form)
    end

    context "form does not exist" do
      it "returns nil" do
        expect(presenter.form(:nonexistent)).to be nil
      end
    end
  end

  describe "component" do
    let :view do
      Pakyow::Presenter::View.new("<div ui=\"post\"></div>")
    end

    it "returns the component" do
      expect(presenter.component(:post)).to be_instance_of(Pakyow::Presenter::Presenter)
      expect(presenter.component(:post).view).to be_instance_of(Pakyow::Presenter::View)
    end

    context "component does not exist" do
      it "returns nil" do
        expect(presenter.component(:nonexistent)).to be nil
      end
    end
  end
end
