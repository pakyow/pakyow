require 'pakyow/support/dup'

describe Pakyow::Utils::Dup do
  describe 'deep' do
    skip
  end

  describe 'uncloneables' do
    describe 'Symbol' do
      it 'is uncloneable' do
        expect(Pakyow::Utils::Dup::UNCLONEABLE).to include Symbol
      end
    end

    describe 'Fixnum' do
      it 'is uncloneable' do
        expect(Pakyow::Utils::Dup::UNCLONEABLE).to include Fixnum
      end
    end

    describe 'NilClass' do
      it 'is uncloneable' do
        expect(Pakyow::Utils::Dup::UNCLONEABLE).to include NilClass
      end
    end

    describe 'TrueClass' do
      it 'is uncloneable' do
        expect(Pakyow::Utils::Dup::UNCLONEABLE).to include TrueClass
      end
    end

    describe 'FalseClass' do
      it 'is uncloneable' do
        expect(Pakyow::Utils::Dup::UNCLONEABLE).to include FalseClass
      end
    end
  end
end
