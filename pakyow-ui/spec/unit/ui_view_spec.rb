require_relative '../spec_helper'
require_relative '../../lib/pakyow-ui/ui_view'

describe Pakyow::UI::UIView do
  let :scope do
    :post
  end

  let :view do
    Pakyow::UI::UIView.new(scope)
  end

  describe '#initialize' do
    it 'sets the scope' do
      expect(view.scoped_as).to eq(scope)
    end

    it 'sets instructions' do
      expect(view.instructions).to eq([])
    end
  end

  describe '#scoped_as' do
    it 'returns the scope' do
      expect(view.scoped_as).to eq(scope)
    end
  end

  describe '#finalize' do
    it 'returns the full instruction set'
  end

  describe '#bind' do
    it 'mixes in the bindings' do
      view.bind({ one: 'one' }, bindings: { two: Proc.new { 'two' } })
      expect(view.finalize[0][1][0][:two]).to eq('two')
    end
  end

  #TODO test all ze view methods
end
