require_relative '../spec_helper'
require 'pakyow/ui/channel_builder'

RSpec.describe Pakyow::UI::ChannelBuilder do
  describe '#build' do
    let :scope do
      :post
    end

    let :mutation do
      :list
    end

    let :qualifiers do
      [:id]
    end

    let :data do
      { id: 1 }
    end

    let :channel do
      "scope:#{scope};mutation:#{mutation}::id:#{data[:id]}"
    end

    it 'builds the channel name with scope, mutation, and qualifiers' do
      expect(
        Pakyow::UI::ChannelBuilder.build(
          scope: scope,
          mutation: mutation,
          qualifiers: qualifiers,
          data: data
        )
      ).to eq(channel)
    end
  end
end
