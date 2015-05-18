require_relative 'support/helper'

describe Page do
  before do
    @store = ViewStore.new('spec/support/views')
  end

  it "allows access to containers" do
    container = @store.page('/').container(:default)

    expect(container).to be_a(Container)
    expect(container.to_html.strip).to eq 'index'
  end
end
