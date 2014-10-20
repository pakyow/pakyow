require_relative 'support/helper'

describe 'applying an empty set to a view' do
  let(:view) {
    Pakyow::Presenter::View.new(<<-D)
    <div data-scope="foo"></div>
    D
  }

  it 'removes the view' do
    view.apply([])
    expect(view.to_s).to be_empty
  end
end
