require_relative '../support/unit_helper'
require 'pakyow/test_help/mocks/status_mock'

describe Pakyow::TestHelp::MockStatus do
  let :code do
    200
  end

  let :mock do
    Pakyow::TestHelp::MockStatus.new(code)
  end

  it 'initializes with value' do
    expect(mock.value).to eq(code)
  end

  it 'can be typecasted to an integer' do
    expect(mock.to_i).to eq(code)
  end

  describe 'equality' do
    it 'is equal to the identical status code' do
      expect(mock).to eq(code)
    end

    it 'is equal to the nice name of status' do
      expect(mock).to eq(:ok)
    end
  end
end
