RSpec.describe "setting up a select field for multiple values" do
  include_context "app"

  it "appends [] to the field name" do
    response = call("/form/select-multiple")
    expect(response[0]).to eq(200)
    expect(response[2]).to include("name=\"post[tags][]\"")
  end
end
