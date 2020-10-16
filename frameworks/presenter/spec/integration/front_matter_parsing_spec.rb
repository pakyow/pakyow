require "pakyow/presenter/templates"
require "pakyow/presenter/processor"

RSpec.describe "parsing front matter from view templates" do
  let :templates do
    Pakyow::Presenter::Templates.new(
      :test,
      File.expand_path("../../features/support/views", __FILE__),
      processor: Pakyow::Presenter::ProcessorCaller.new([])
    )
  end

  let :page do
    templates.info("/front_matter")[:page]
  end

  it "parses front matter" do
    expect(page.info["foo"]).to eq("bar")
    expect(page.to_s.strip).to eq("front matter page")
  end

  context "when the template store does not have a processor" do
    let :templates do
    Pakyow::Presenter::Templates.new(
      :test,
      File.expand_path("../../features/support/views", __FILE__)
    )
  end

    it "parses front matter" do
      expect(page.info["foo"]).to eq("bar")
      expect(page.to_s.strip).to eq("front matter page")
    end
  end
end
