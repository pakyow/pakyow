require_relative "./shared"

RSpec.describe "populating groups of options" do
  include_context "options_for"

  let :view_path do
    "/presentation/forms/options_for/grouped_select"
  end

  let :options do
    [
      ["group1", [[1, "1.1"], [2, "1.2"], [3, "1.3"]]],
      ["group2", [[4, "2.1"]]]
    ]
  end

  let :perform do
    local = self
    Proc.new do |form|
      form.grouped_options_for(local.binding, local.options)
    end
  end

  it "renders in an expected way" do
    expect(rendered).to include_sans_whitespace(
      <<~HTML
        <form data-b="post" data-c="form">
          <select data-b="tag" data-c="form" name="post[tag]">
            <optgroup label="group1">
              <option value="1">1.1</option>
              <option value="2">1.2</option>
              <option value="3">1.3</option>
            </optgroup>

            <optgroup label="group2">
              <option value="4">2.1</option>
            </optgroup>
          </select>

          <script type="text/template" data-b="tag" data-c="form">
            <select data-b="tag" data-c="form">
              <option data-b="name" data-c="form">existing</option>
            </select>
          </script>
        </form>
      HTML
    )
  end
end
