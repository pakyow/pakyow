require_relative 'support/int_helper'

context 'when testing a route that reroutes' do
  it 'appears to have rerouted' do
    get :reroute do |sim|
      expect(sim.rerouted?).to eq(true)
    end
  end

  it 'appears to have rerouted to a path' do
    get :reroute do |sim|
      expect(sim.rerouted?(to: :default)).to eq(true)
    end
  end
end
