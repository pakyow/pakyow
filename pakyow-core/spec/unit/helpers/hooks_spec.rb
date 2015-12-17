require 'core/helpers/hooks'

module Spec
  class HooksAppMock
    extend Pakyow::Helpers::Hooks
  end
end

describe Pakyow::Helpers::Hooks do
  let :mock do
    Spec::HooksAppMock
  end

  let :trigger do
    Pakyow::Helpers::Hooks::TRIGGERS.first
  end

  after do
    mock.instance_variables.each do |ivar|
      mock.remove_instance_variable(ivar)
    end
  end

  describe '::TRIGGERS' do
    it 'includes `init`' do
      expect(Pakyow::Helpers::Hooks::TRIGGERS).to include(:init)
    end

    it 'includes `load`' do
      expect(Pakyow::Helpers::Hooks::TRIGGERS).to include(:load)
    end

    it 'includes `process`' do
      expect(Pakyow::Helpers::Hooks::TRIGGERS).to include(:process)
    end

    it 'includes `route`' do
      expect(Pakyow::Helpers::Hooks::TRIGGERS).to include(:route)
    end

    it 'includes `match`' do
      expect(Pakyow::Helpers::Hooks::TRIGGERS).to include(:match)
    end

    it 'includes `error`' do
      expect(Pakyow::Helpers::Hooks::TRIGGERS).to include(:error)
    end

    it 'includes `configure`' do
      expect(Pakyow::Helpers::Hooks::TRIGGERS).to include(:configure)
    end
  end

  describe '::before' do
    context 'called with a valid trigger and block' do
      let :block do
        -> {}
      end

      before do
        mock.before(trigger, &block)
      end

      it 'registers the block for trigger' do
        expect(mock.hook(:before, trigger).first).to be(block)
      end
    end

    context 'called with a non-existent trigger and block' do
      it 'raises an ArgumentError' do
        expect { mock.before(:foo) {} }.to raise_exception(ArgumentError)
      end
    end

    context 'called without a block' do
      it 'raises an ArgumentError' do
        expect { mock.before(trigger) }.to raise_exception(ArgumentError)
      end
    end
  end

  describe '::after' do
    context 'called with a valid trigger and block' do
      let :block do
        -> {}
      end

      before do
        mock.after(trigger, &block)
      end

      it 'registers the block for trigger' do
        expect(mock.hook(:after, trigger).first).to be(block)
      end
    end

    context 'called with an invalid trigger and block' do
      it 'raises an ArgumentError' do
        expect { mock.after(:foo) {} }.to raise_exception(ArgumentError)
      end
    end

    context 'called without a block' do
      it 'raises an ArgumentError' do
        expect { mock.after(trigger) }.to raise_exception(ArgumentError)
      end
    end
  end

  describe '::hook' do
    context 'called with a valid type and trigger' do
      context 'and a hook is registered' do
        let :block do
          -> {}
        end

        before do
          mock.before(trigger, &block)
        end

        it 'returns an Array containing the hook' do
          expect(mock.hook(:before, trigger)).to eq([block])
        end
      end

      context 'and a hook is not registered' do
        it 'returns an empty Array' do
          expect(mock.hook(:before, trigger)).to eq([])
        end
      end
    end

    context 'called with an invalid type' do
      it 'raises an ArgumentError' do
        expect { mock.hook(:foo, trigger) }.to raise_exception(ArgumentError)
      end
    end

    context 'called with an invalid trigger' do
      it 'raises an ArgumentError' do
        expect { mock.hook(:before, :foo) }.to raise_exception(ArgumentError)
      end
    end
  end
end
