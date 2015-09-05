require_relative 'support/int_helper'
require 'securerandom'

context 'when testing a route that writes to the log' do
  describe 'the log' do
    let :message do
      SecureRandom.hex
    end

    it 'contains the logged message' do
      get :log, with: { message: message } do |sim|
        expect(sim.log).to include(message)
      end
    end
  end
end
