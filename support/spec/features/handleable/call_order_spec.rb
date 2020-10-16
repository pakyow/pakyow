RSpec.describe "handleable call order" do
  let(:handleable) {
    Class.new do
      include Pakyow::Support::Handleable
    end
  }

  attr_accessor :handled

  before do
    local = self

    handleable.handle :foo do
      local.handled << :foo_1
    end

    handleable.handle :foo do
      local.handled << :foo_2
    end

    @handled = []
  end

  after do
    @handled.clear
  end

  it "calls lifo" do
    handleable.trigger :foo

    expect(handled).to eq([:foo_2, :foo_1])
  end
end
