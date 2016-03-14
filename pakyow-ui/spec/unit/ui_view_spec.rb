require_relative '../spec_helper'
require 'pakyow/ui/ui_view'

describe Pakyow::UI::UIView do
  let :scope do
    :post
  end

  let :view do
    Pakyow::UI::UIView.new(scope)
  end

  it 'includes helpers'

  describe '#initialize' do
    it 'sets the scope' do
      expect(view.scoped_as).to eq(scope)
    end

    it 'sets instructions' do
      expect(view.instructions).to eq([])
    end

    describe 'context' do
      it 'is created'
      it 'includes the session'
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
      view.bind({ one: 'one' }, bindings: { two: proc { 'two' } })
      expect(view.finalize[0][1][0][:two]).to eq('two')
    end
  end

  describe '#with' do
    context 'when block arity equals 0' do
      it 'builds up the instructions' do
        view.with do
          bind(one: 'one')
        end

        expect(view.finalize[0][1][0][:one]).to eq('one')
      end
    end

    context 'when block arity equals 1' do
      it 'builds up the instructions' do
        view.with do |view|
          view.bind(one: 'one')
        end

        expect(view.finalize[0][1][0][:one]).to eq('one')
      end
    end
  end

  # TODO: test all ze view methods
end
