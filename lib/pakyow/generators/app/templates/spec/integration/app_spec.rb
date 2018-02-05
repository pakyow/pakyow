require_relative '../spec_helper'

describe Pakyow::App do
  context 'when navigating to the default route' do
    it 'succeeds' do
      get :default do |sim|
        expect(sim.status).to eq(200)
      end
    end

    it 'says hello' do
      get :default do |sim|
        expect(sim.log).to include('hello')
      end
    end
  end
end
