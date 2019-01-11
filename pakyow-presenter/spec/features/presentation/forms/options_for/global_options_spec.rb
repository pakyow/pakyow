RSpec.describe "defining global options in the presenter" do
  let :presenter do
    presenter_class.new(view)
  end

  let :view do
    Pakyow::Presenter::View.new(
      <<~HTML
        <form binding="post">
          <select binding="tag">
            <option binding="name">existing</option>
          </select>
        </form>
      HTML
    )
  end

  context "options are defined as a block" do
    let :presenter_class do
      Class.new(Pakyow::Presenter::Presenter) do
        options_for :post, :tag do
          $context = self

          [
            { id: 1, name: "foo" },
            { id: 2, name: "bar" },
            { id: 3, name: "baz" }
          ]
        end
      end
    end

    after do
      $context = nil
    end

    it "applies the options to the form" do
      expect(presenter.to_s(clean_bindings: false)).to eq_sans_whitespace(
        <<~HTML
          <form data-b="post" data-c="form">
            <select data-b="tag" data-c="form">
              <option value="1">foo</option>
              <option value="2">bar</option>
              <option value="3">baz</option>
            </select>
          </form>
        HTML
      )
    end

    it "calls the block in context of the presenter instance" do
      presenter.to_s(clean_bindings: false)
      expect($context).to be_instance_of(presenter_class)
    end
  end

  context "options are defined inline" do
    let :presenter_class do
      Class.new(Pakyow::Presenter::Presenter) do
        options_for :post, :tag, [
          { id: 1, name: "foo" },
          { id: 2, name: "bar" },
          { id: 3, name: "baz" }
        ]
      end
    end

    it "applies the options to the form" do
      expect(presenter.to_s(clean_bindings: false)).to eq_sans_whitespace(
        <<~HTML
          <form data-b="post" data-c="form">
            <select data-b="tag" data-c="form">
              <option value="1">foo</option>
              <option value="2">bar</option>
              <option value="3">baz</option>
            </select>
          </form>
        HTML
      )
    end
  end
end
