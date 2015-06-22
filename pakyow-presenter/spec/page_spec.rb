require_relative 'support/helper'

describe Pakyow::Presenter::Page do
  before do
    @store = Pakyow::Presenter::ViewStore.new(VIEW_PATH)
  end

  it "allows access to containers" do
    container = @store.page('/').container(:default)

    expect(container).to be_a(Pakyow::Presenter::Container)
    expect(container.to_html.strip).to eq 'index'
  end
end
