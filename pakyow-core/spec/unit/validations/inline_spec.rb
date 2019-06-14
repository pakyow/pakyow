require "pakyow/validations/inline"

RSpec.describe Pakyow::Validations::Inline do
  let :validation do
    Pakyow::Validations::Inline.new("foo", Proc.new {})
  end

  it "has a message" do
    expect(validation.message(**{})).to eq("is invalid")
  end
end
