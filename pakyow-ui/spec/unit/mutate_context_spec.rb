require_relative '../spec_helper'
require_relative '../../lib/pakyow-ui/mutate_context'

describe Pakyow::UI::MutateContext do
  describe '#initialize' do
    it 'sets mutation, view, and data'
  end

  describe '#subscribe' do
    it 'subscribes to the channel'

    context 'when subscribing an empty view collection' do
      it 'inserts an empty element with channel attribute'
    end

    context 'when subscribing to a non-empty view' do
      it 'sets the channel attribute'
    end
  end
end
