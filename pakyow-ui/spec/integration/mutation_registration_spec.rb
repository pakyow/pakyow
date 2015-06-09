require_relative 'support/int_helper'

describe 'registering a collection of mutators' do
  before do
    Pakyow::App.mutators :post do
    end
  end

  it 'registers' do
    expect(Pakyow::App.mutators.keys).to include :post
  end
end
