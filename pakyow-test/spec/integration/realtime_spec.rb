require_relative 'support/int_helper'

RSpec.context 'when testing a route that subscribes to a channel' do
  let :channel do
    'foo'
  end

  it 'appears to have subscribed' do
    get :subscribe, with: { channel: channel } do |sim|
      expect(sim.subscribed?).to eq(true)
    end
  end

  it 'appears to have subscribed to the channel' do
    get :subscribe, with: { channel: channel } do |sim|
      expect(sim.subscribed?(to: channel)).to eq(true)
    end
  end
end

RSpec.context 'when testing a route that unsubscribes to a channel' do
  let :channel do
    'foo'
  end

  it 'appears to have unsubscribed' do
    get :unsubscribe, with: { channel: channel } do |sim|
      expect(sim.unsubscribed?).to eq(true)
    end
  end

  it 'appears to have unsubscribed to the channel' do
    get :unsubscribe, with: { channel: channel } do |sim|
      expect(sim.unsubscribed?(to: channel)).to eq(true)
    end
  end
end

RSpec.context 'when testing a route that pushes to a channel' do
  let :channel do
    'foo'
  end

  let :message do
    'bar'
  end

  it 'appears to have pushed' do
    get :push, with: { channel: channel, message: message } do |sim|
      expect(sim.pushed?).to eq(true)
    end
  end

  it 'appears to have pushed to the channel' do
    get :push, with: { channel: channel, message: message } do |sim|
      expect(sim.pushed?(to: channel)).to eq(true)
    end
  end

  it 'appears to have pushed the message to the channel' do
    get :push, with: { channel: channel, message: message } do |sim|
      expect(sim.pushed?(message, to: channel)).to eq(true)
    end
  end
end
