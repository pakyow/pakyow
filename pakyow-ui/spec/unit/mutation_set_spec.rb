require_relative '../spec_helper'
require_relative '../../lib/pakyow-ui/mutation_set'

describe Pakyow::UI::MutationSet do
  let :set_class do
    Pakyow::UI::MutationSet
  end

  let :set do
    set_class.new(&block)
  end

  let :block do
    Proc.new {}
  end

  let :name do
    :post
  end

  let :qualifiers do
    [:id]
  end

  describe '#initialize' do
    it 'sets @mutations' do
      expect(set.mutations).to eq({})
    end

    it 'instance_execs block' do
      expect_any_instance_of(set_class).to receive(:instance_exec)
      set
    end
  end

  describe '#mutator' do
    context 'with a name' do
      it 'stores mutation by name with default values' do
        set.mutator(name, &block)

        mutation = set.mutations[name]
        expect(mutation[:fn]).to eq block
        expect(mutation[:qualifiers]).to eq []
      end
    end

    context 'with a name, fn, and qualifiers' do
      it 'stores a mutation by name with fn, qualifiers' do
        set.mutator(name, qualify: qualifiers, &block)

        mutation = set.mutations[name]
        expect(mutation[:fn]).to eq block
        expect(mutation[:qualifiers]).to eq qualifiers
      end
    end
  end

  describe '#mutation' do
    context 'and a mutation exists with name' do
      before do
        set.mutator(name, &block)
      end

      it 'returns mutation' do
        expect(set.mutation(name)).not_to be_nil
      end
    end

    context 'and a mutation does not exist with name' do
      it 'raises KeyError' do
        expect {
          set.mutation(name)
        }.to raise_error(KeyError)
      end
    end
  end

  describe '#each' do
    it 'delegates to @mutations' do
      expect(set.mutations).to receive(:each)
      set.each {}
    end
  end
end
