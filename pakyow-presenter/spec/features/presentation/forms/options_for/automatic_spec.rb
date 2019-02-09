RSpec.describe "automatically setting up options for a form" do
  let :presenter do
    Pakyow::Presenter::Presenter.new(view)
  end

  let :view do
    Pakyow::Presenter::View.new(
      <<~HTML
        <form binding="post">
          <input binding="title" type="text">
          <select binding="tag"><option>existing</option></select>
          <input type="checkbox" binding="colors">
          <input type="radio" binding="enabled">
        </form>
      HTML
    )
  end

  let :form do
    presenter.form(:post).setup(object)
  end

  context "field is a select" do
    context "value is an array" do
      it "sets up the options"
    end

    context "value is an object" do
      it "sets up the option"
    end

    context "value is a boolean" do
      it "sets up the option"
    end
  end

  context "field is a checkbox" do
    context "value is an array" do
      it "sets up the options"
    end

    context "value is an object" do
      it "sets up the option"
    end

    context "value is a boolean" do
      it "sets up the option"
    end
  end

  context "field is a radio button" do
    context "value is an array" do
      it "sets up the options"
    end

    context "value is an object" do
      it "sets up the option"
    end

    context "value is a boolean" do
      it "sets up the option"
    end
  end

  context "field is a nested binding" do
    context "value is an array" do
      it "sets up the options"
    end

    context "value is an object" do
      it "sets up the option"
    end

    context "value is a boolean" do
      it "sets up the option"
    end
  end

  context "option has already been setup" do
    it "does not try to setup automatically"
  end
end
