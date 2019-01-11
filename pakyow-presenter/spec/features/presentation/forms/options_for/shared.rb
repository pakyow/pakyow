RSpec.shared_context "options_for" do
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
    presenter.form(:post).setup
  end

  let :binding do
    :tag
  end

  before do
    if respond_to?(:block)
      form.options_for(binding, &block)
    else
      form.options_for(binding, options)
    end
  end
end
