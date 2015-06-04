require 'support/helper'

describe 'Response' do
  it 'extends rack response' do
    expect(Pakyow::Response.superclass).to eq Rack::Response
  end
end
