RSpec.describe "forms with unused bindings" do
  include_context "app"

  it "renders with the unused bindings" do
    expect(call("/form")[2].body.read).to include_sans_whitespace(
      <<~HTML
        <form data-b="post" data-c="form">
      HTML
    )

    expect(call("/form")[2].body.read).to include_sans_whitespace(
      <<~HTML
        <input data-b="title" type="text" data-c="form" name="post[title]">
      HTML
    )
  end
end
