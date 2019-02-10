require_relative "./shared"

RSpec.describe "populating groups of options" do
  include_context "options_for"

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

  let :options do
    [
      ["group1", [[1, "1.1"], [2, "1.2"], [3, "1.3"]]],
      ["group2", [[4, "2.1"]]]
    ]
  end

  let :tag_view do
    Pakyow::Presenter::View.new(
      form.find(:tag).view.to_s
    )
  end

  def perform
    form.grouped_options_for(binding, options)
  end

  it "creates a group for each group" do
    expect(tag_view.object.find_significant_nodes(:optgroup).count).to eq(2)
  end

  it "sets the label for each optgroup" do
    groups = tag_view.object.find_significant_nodes(:optgroup)
    expect(groups[0].attributes[:label]).to eq("group1")
    expect(groups[1].attributes[:label]).to eq("group2")
  end

  it "creates an option for each value" do
    groups = tag_view.object.find_significant_nodes(:optgroup)
    expect(groups[0].find_significant_nodes(:option).count).to eq(3)
    expect(groups[1].find_significant_nodes(:option).count).to eq(1)
  end

  it "sets the submitted value for each option" do
    groups = tag_view.object.find_significant_nodes(:optgroup)

    group1_options = groups[0].find_significant_nodes(:option)
    expect(group1_options[0].attributes[:value]).to eq("1")
    expect(group1_options[1].attributes[:value]).to eq("2")
    expect(group1_options[2].attributes[:value]).to eq("3")

    group2_options = groups[1].find_significant_nodes(:option)
    expect(group2_options[0].attributes[:value]).to eq("4")
  end

  it "sets the presentation value for each option" do
    groups = tag_view.object.find_significant_nodes(:optgroup)

    group1_options = groups[0].find_significant_nodes(:option)
    expect(group1_options[0].text).to eq("1.1")
    expect(group1_options[1].text).to eq("1.2")
    expect(group1_options[2].text).to eq("1.3")

    group2_options = groups[1].find_significant_nodes(:option)
    expect(group2_options[0].text).to eq("2.1")
  end
end
