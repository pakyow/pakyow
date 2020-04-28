RSpec.describe "handling exceptions" do
  let(:handleable) {
    Class.new do
      include Pakyow::Support::Handleable
    end
  }

  attr_accessor :handled

  before do
    local = self

    handleable.handle Exception do
      local.handled = true
    end
  end

  it "calls the handler" do
    handleable.handling do
      raise Exception.new
    end

    expect(handled).to be(true)
  end
end
