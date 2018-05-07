RSpec.describe "presenting forms" do
  include_context "testable app"

  let :presenter do
    Pakyow.apps.first.class.const_get(:Presenter).new(view)
  end

  let :view do
    Pakyow::Presenter::View.new(
      <<~HTML
        <form binding=\"post\">
          <input binding=\"title\" type="text">
          <input@foo type="text" name="foo">
        </form>
      HTML
    )
  end

  let :form do
    presenter.form(:post)
  end

  describe "finding a form by name" do
    it "returns a form presenter, wrapping a form object" do
      expect(form).to be_instance_of(Pakyow::Forms::FormPresenter)
      expect(form.view).to be_instance_of(Pakyow::Forms::FormView)
    end

    context "form with name does not exist" do
      it "returns nil" do
        expect(presenter.form(:comment)).to be nil
      end
    end
  end

  describe "field names" do
    it "creates field names based on bindings" do
      expect(form.to_s).to include("name=\"post[title]\"")
    end

    it "does not override names in the template" do
      expect(form.to_s).to include("name=\"foo\"")
    end
  end

  describe "setting the form action" do
    context "passed a string" do
      before do
        form.action = "foo"
      end

      it "sets the action" do
        expect(presenter.to_s).to include("action=\"foo\"")
      end
    end
  end

  describe "setting the form method" do
    context "method is get" do
      before do
        form.method = :get
      end

      it "sets the method to get" do
        expect(presenter.to_s).to include("method=\"get\"")
      end
    end

    context "method is post" do
      before do
        form.method = :post
      end

      it "sets the method to post" do
        expect(presenter.to_s).to include("method=\"post\"")
      end
    end

    context "method is not get or post" do
      before do
        form.method = :delete
      end

      it "sets the method to post" do
        expect(presenter.to_s).to include("method=\"post\"")
      end

      it "inserts the method override input" do
        expect(presenter.to_s).to include("<input type=\"hidden\" name=\"_method\" value=\"delete\">")
      end
    end
  end
end
