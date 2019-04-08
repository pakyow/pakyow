RSpec.describe "yielding to the options_for block" do
  include_context "app"

  let :presenter do
    Pakyow::Presenter::Presenter.new(view, app: Pakyow.apps[0])
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

  it "it yields field" do
    yielded_field = nil
    presenter.form(:post).options_for(:tag) do |field|
      yielded_field = field
      []
    end

    expect(yielded_field).to be_instance_of(Pakyow::Presenter::VersionedView)
  end
end
