require 'support/helper'

describe 'ResponseTest' do
  it 'extends rack response' do
    expect(Rack::Response).to eq Pakyow::Response.superclass
  end
end
