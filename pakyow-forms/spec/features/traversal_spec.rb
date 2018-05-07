RSpec.describe "form traversal via presenter" do
  include_context "testable app"

  let :presenter do
    Pakyow.apps.first.class.const_get(:Presenter).new(view)
  end

  describe "form" do
    let :view do
      Pakyow::Presenter::View.new("<form binding=\"post\"></form>")
    end

    it "returns the form" do
      expect(presenter.form(:post)).to be_instance_of(Pakyow::Forms::FormPresenter)
      expect(presenter.form(:post).view).to be_instance_of(Pakyow::Forms::FormView)
    end

    context "form does not exist" do
      it "returns nil" do
        expect(presenter.form(:nonexistent)).to be nil
      end
    end
  end
end
