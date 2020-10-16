require "pakyow/support/configurable"

RSpec.describe "accessing config on frozen instances" do
  let(:object) {
    Class.new {
      include Pakyow::Support::Configurable
    }
  }

  let(:instance) {
    object.new
  }

  before do
    instance.freeze
  end

  it "is accessible" do
    expect(instance.config.class.ancestors).to include(Pakyow::Support::Configurable::Config)
  end
end
