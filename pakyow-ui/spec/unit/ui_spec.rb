require_relative '../spec_helper'
require 'pakyow/ui/ui'

RSpec.describe Pakyow::UI::UI do
  let :ui do
    Pakyow::UI::UI.new
  end

  let :mutators do
    {
      post: proc {},
      user: proc {}
    }
  end

  let :mutator_instance do
    instance_double(Pakyow::UI::Mutator, reset: mutator_reset)
  end

  let :mutator_reset do
    instance_double(Pakyow::UI::Mutator)
  end

  before do
    allow(Pakyow::UI::Mutator).to receive(:instance).and_return(mutator_instance)
    allow(mutator_reset).to receive(:set)
  end

  describe '#load' do
    it 'resets the Mutator instance' do
      expect(mutator_instance).to receive(:reset)
      ui.load(mutators, {})
    end

    it 'calls Mutator#set for each' do
      mutators.each do |name, block|
        expect(mutator_reset).to receive(:set).with(name, &block)
      end

      ui.load(mutators, {})
    end
  end

  describe '#mutated' do
    it 'mutates for all scope mutations'
    it 'pushes instructions down the socket'
  end
end
