RSpec.describe "prototype ui modes" do
  include_context "app"

  let :mode do
    :prototype
  end

  it "uses the mode passed as a param" do
    expect(call("/prototyping/ui_modes?modes[]=one")[2]).to include_sans_whitespace(
      <<~HTML
        <h1>one</h1>
      HTML
    )

    expect(call("/prototyping/ui_modes?modes[]=two")[2]).to include_sans_whitespace(
      <<~HTML
        <h1>two</h1>
      HTML
    )
  end

  it "adds defined modes to the prototype bar" do
    result = call("/prototyping/ui_modes")[2]

    expect(result).to include_sans_whitespace(
      <<~HTML
        UI Mode:
      HTML
    )

    expect(result).to include_sans_whitespace(
      <<~HTML
        <option value="default" selected="selected">Default</option>
        <option value="one">One</option>
        <option value="two">Two</option>
      HTML
    )
  end

  context "not in prototype mode" do
    let :mode do
      :test
    end

    it "does not use the mode passed as a param" do
      result = call("/prototyping/ui_modes?modes[]=two")[2]

      expect(result).not_to include_sans_whitespace(
        <<~HTML
          <div data-b="post">
            <h1>one</h1>
          </div>
        HTML
      )

      expect(result).not_to include_sans_whitespace(
        <<~HTML
          <div data-b="post">
            <h1>two</h1>
          </div>
        HTML
      )
    end
  end
end
