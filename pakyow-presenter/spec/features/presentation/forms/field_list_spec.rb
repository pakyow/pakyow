RSpec.describe "setting up a list of fields for a plural value" do
  let :presenter do
    Pakyow::Presenter::Presenter.new(view)
  end

  let :view do
    Pakyow::Presenter::View.new(
      <<~HTML
        <form binding="profile">
          <input binding="links" type="text">
        </form>
      HTML
    )
  end

  let :form do
    presenter.form(:profile)
  end

  let :object do
    { links: ["foo", "bar", "baz"] }
  end

  it "creates a field for each value" do
    # form.create(object)

    # expect(form.to_s).to include_sans_whitespace(
    #   <<~HTML
    #     <input data-b="links" type="text" data-c="form" name="profile[links][]" value="foo">
    #   HTML
    # )

    # expect(form.to_s).to include_sans_whitespace(
    #   <<~HTML
    #     <input data-b="links" type="text" data-c="form" name="profile[links][]" value="bar">
    #   HTML
    # )

    # expect(form.to_s).to include_sans_whitespace(
    #   <<~HTML
    #     <input data-b="links" type="text" data-c="form" name="profile[links][]" value="baz">
    #   HTML
    # )
  end
end
