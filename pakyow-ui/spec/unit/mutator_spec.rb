require_relative '../spec_helper'
require_relative '../../lib/pakyow-ui/mutator'

describe Pakyow::UI::Mutator do
  let :mutator_class do
    Pakyow::UI::Mutator
  end

  let :set_class do
    Pakyow::UI::MutationSet
  end

  let :mutator do
    mutator_class.instance
  end

  let :block do
    Proc.new {}
  end

  let :scope do
    :post
  end

  before do
    mutator.reset
  end

  it 'is a singleton' do
    expect(mutator_class.ancestors).to include Singleton
  end

  describe '#initialize' do
    it 'sets @sets' do
      mutator
      expect(mutator.sets).to eq({})
    end
  end

  describe '#reset' do
    before do
      mutator.instance_variable_set(:@sets, { foo: :bar })
    end

    it 'resets @sets' do
      mutator.reset
      expect(mutator.sets).to eq({})
    end

    it 'returns self' do
      expect(mutator.reset).to be(mutator)
    end
  end

  describe '#set' do
    it 'creates a MutationSet' do
      expect(set_class).to receive(:new)
      mutator.set(scope, &block)
    end

    it 'stores set by scope' do
      mutator.set(scope, &block)
      expect(mutator.sets.keys).to include scope
      expect(mutator.sets[scope]).to be_an_instance_of set_class
    end
  end

  describe '#mutation' do
    let :name do
      :list
    end

    context 'and a mutation exists with name for scope' do
      before do
        mutator.set(scope, &block)
      end

      after do
        mutator.reset
      end

      it 'finds mutation with name for scope' do
        expect_any_instance_of(set_class).to receive(:mutation).with(name)
        mutator.mutation(scope, name)
      end
    end

    context 'and a mutation does not exist with name for scope' do
      it 'returns nil' do
        expect(mutator.mutation(scope, name)).to be_nil
      end
    end
  end

  describe '#mutations_by_scope' do
    context 'and a set exists for scope' do
      before do
        mutator.set(scope, &block)
      end

      after do
        mutator.reset
      end

      it 'returns the set' do
        expect(mutator.mutations_by_scope(scope)).to be_instance_of(set_class)
      end
    end

    context 'and a set does not exist for scope' do
      it 'returns nil' do
        expect(mutator.mutations_by_scope(scope)).to be_nil
      end
    end
  end

  describe '#mutate' do
    before do
      mutator.set(scope) do
        mutator :list do |view, data|
          PerformedMutations.perform :list, view, data
        end
      end
    end

    after do
      mutator.reset
    end

    let :view do
      view = View.new
      view.scoped_as = scope
      view
    end

    let :data do
      [:one, :two, :three]
    end

    it 'calls the mutation with view and data' do
      mutator.mutate(:list, view, data)
      expect(PerformedMutations.performed.keys).to include :list

      performed = PerformedMutations.performed[:list]
      expect(performed[:view]).to be view
      expect(performed[:data]).to be data
    end

    it 'returns a mutate context' do
      expect(mutator.mutate(:list, view, data)).to be_instance_of(Pakyow::UI::MutateContext)
    end
  end
end
