RSpec.describe "initially rendering a form with an error component" do
  include_context "app"

  it "removes the errors binding" do
    expect(call("/")[2]).to_not include('<li data-b="error"')
  end

  it "does not add an errored class to the form" do
    expect(call("/")[2]).to include('<form data-b="post" data-ui="form" data-c="form"')
  end

  it "adds a hidden class to the errors" do
    expect(call("/")[2]).to include('<ul data-ui="form-errors" class="ui-hidden">')
  end

  context "form component does not contain errors" do
    it "does not blow up" do
      expect(call("/no-errors")[0]).to eq(200)
    end
  end
end
