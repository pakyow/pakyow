require_relative '../spec_helper'

RSpec.describe Pakyow::Presenter::View do
  let :view do
    Pakyow::Presenter::View.new
  end

  describe '#length' do
    it 'returns 1' do
      expect(view.length).to eq(1)
    end
  end

  describe '#first' do
    it 'returns self' do
      expect(view.first).to eq(view)
    end
  end

  describe '#with' do
    it "yields context" do
      view.with { |ctx|
        expect(view).to eq ctx
      }
    end

    it "calls block in context of view" do
      ctx = nil
      view.with {
        ctx = self
      }

      expect(view).to eq ctx
    end
  end

  describe '#for' do
    let :data do
      [{}]
    end

    it "yields each view/datum pair" do
      view.for(data) do |ctx, datum|
        expect(view).to eq ctx
        expect(data[0]).to eq datum
      end
    end

    it "calls block in context of view, yielding datum" do
      ctx = nil
      ctx_datum = nil
      view.for(data) do |datum|
        ctx = self
        ctx_datum = datum
      end

      expect(view).to eq ctx
      expect(data[0]).to eq ctx_datum
    end

    it "stops when no more views" do
      count = 0
      view.for(3.times.to_a) do |datum|
        count += 1
      end

      expect(count).to eq 1
    end

    it "handles non-array data" do
      data = {}
      view.for(data) do |ctx, datum|
        expect(data).to eq datum
      end
    end
  end
end
