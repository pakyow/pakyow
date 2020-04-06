require "pakyow/presenter/errors"

RSpec.describe Pakyow::Error do
  it "is bindable" do
    expect(described_class.ancestors).to include(Pakyow::Support::Bindable)
  end
end
