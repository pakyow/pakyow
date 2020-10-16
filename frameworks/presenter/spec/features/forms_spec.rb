RSpec.describe "presenting forms" do
  include_context "app"

  let :presenter do
    Pakyow::Presenter::Presenter.new(view, app: Pakyow.apps[0])
  end

  let :view do
    Pakyow::Presenter::View.new(
      <<~HTML
        <form binding="post">
          <input binding="title" type="text">
          <input binding="foo" type="text" name="foo">
        </form>
      HTML
    )
  end

  let :form do
    presenter.form(:post).setup(title: "", foo: "")
  end

  describe "finding a form by name" do
    it "returns a form presenter, wrapping a form object" do
      expect(form).to be_instance_of(Pakyow::Presenter::Presenters::Form)
      expect(form.view).to be_instance_of(Pakyow::Presenter::Views::Form)
    end

    it "does not find forms using the find method" do
      expect(presenter.find(:post)).to be nil
    end

    context "form with name does not exist" do
      it "returns nil" do
        expect(presenter.form(:comment)).to be nil
      end
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
        expect(presenter.to_s).to include("<input type=\"hidden\" name=\"pw-http-method\" value=\"delete\">")
      end
    end
  end
end
