require_relative 'support/helper'

describe Page do
  before do
    capture_stdout do
      @store = ViewStore.new('test/support/views')
    end
  end

  it "allows access to containers" do
    container = @store.page('/').container(:default)

    assert_instance_of Container, container
    assert_equal 'index', container.to_html.strip
  end
end
