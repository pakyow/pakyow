require_relative "./shared"

RSpec.describe "populating options for an nonexistent field" do
  include_context "options_for"

  let :options do
    []
  end

  let :perform do
    local = self
    Proc.new do |form|
      form.options_for(:foo, local.options)
    rescue => error
      local.instance_variable_set(:@error, error)
    end
  end

  it "fails" do
    rendered
    expect(@error).to be_instance_of(ArgumentError)
    expect(@error.message).to eq("could not find field named `foo'")
  end
end
