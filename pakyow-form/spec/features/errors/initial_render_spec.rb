RSpec.describe "initially rendering a form with an error component" do
  include_context "app"

  it "removes the errors binding" do
    expect(call("/")[2].body.read).to_not include('<li data-b="error"')
  end

  it "does not add an errored class to the form" do
    expect(call("/")[2].body.read).to include('<form data-b="post" data-ui="form" data-c="form"')
  end

  context "form component does not contain errors" do
    it "does not blow up" do
      expect(call("/no-errors")[0]).to eq(200)
    end
  end
end
