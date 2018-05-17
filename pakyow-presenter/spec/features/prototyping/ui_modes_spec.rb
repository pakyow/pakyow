RSpec.describe "prototype ui modes" do
  include_context "testable app"

  let :app_definition do
    Proc.new {
      instance_exec(&$presenter_app_boilerplate)
    }
  end

  let :mode do
    :prototype
  end

  it "uses the mode passed as a param" do
    expect(call("/prototyping/ui_modes?mode=one")[2].body.read).to include_sans_whitespace(
      <<~HTML
        <div data-b="post" data-v="one">
          <h1>one</h1>
        </div>
      HTML
    )

    expect(call("/prototyping/ui_modes?mode=two")[2].body.read).to include_sans_whitespace(
      <<~HTML
        <div data-b="post" data-v="two">
          <h1>two</h1>
        </div>
      HTML
    )
  end

  it "adds defined modes to the prototype bar" do
    result = call("/prototyping/ui_modes")[2].body.read

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
      result = call("/prototyping/ui_modes?mode=two")[2].body.read

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
