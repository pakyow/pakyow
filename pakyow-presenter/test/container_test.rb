require_relative 'support/helper'

describe Container do
  before do
    capture_stdout do
      @store = ViewStore.new('test/support/views')
    end
  end

  it "can be typecast to View" do
    container = @store.page('/').container(:default)

    assert_instance_of View, container.to_view
  end
end
