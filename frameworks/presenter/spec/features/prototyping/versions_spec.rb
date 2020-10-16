RSpec.describe "presenting versions in prototype mode" do
  include_context "app"

  let :mode do
    :prototype
  end

  it "renders all versions" do
    expect(call("/prototyping/versions")[2]).to include_sans_whitespace(
      <<~HTML
        <div data-b="post" data-v="one">
          one
        </div>

        <div data-b="post" data-v="two">
          two
        </div>
      HTML
    )
  end
end
