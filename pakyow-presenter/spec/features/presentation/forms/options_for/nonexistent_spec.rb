require_relative "./shared"

RSpec.describe "populating options for an nonexistent field" do
  include_context "options_for"

  let :options do
    []
  end

  it "fails" do
    expect { form.options_for(:foo, []) }.to raise_error(ArgumentError)
  end
end
