require_relative 'support/int_helper'

RSpec.context 'when testing a route that mutates a view' do
  it 'appears to have mutated' do
    get :mutate do |sim|
      expect(sim.view.scope(:post).mutated?).to eq(true)
    end
  end

  it 'appears to have mutated with a mutation' do
    get :mutate do |sim|
      expect(sim.view.scope(:post).mutated?(:list)).to eq(true)
    end
  end

  it 'appears to have mutated with a mutation and data' do
    get :mutate do |sim|
      expect(sim.view.scope(:post).mutated?(:list, data: [:foo])).to eq(true)
    end
  end

  it 'does not appear to have mutated with a mutation and incorrect data' do
    get :mutate do |sim|
      expect(sim.view.scope(:post).mutated?(:list, data: [:bar])).to eq(false)
    end
  end

  it 'does not appear to have been subscribed' do
    get :mutate do |sim|
      expect(sim.view.scope(:post).subscribed?).to eq(false)
    end
  end
end

RSpec.context 'when testing a route that mutates and subscribes a view' do
  it 'appears to have been subscribed' do
    get :mutate_subscribe do |sim|
      expect(sim.view.scope(:post).subscribed?).to eq(true)
    end
  end
end
