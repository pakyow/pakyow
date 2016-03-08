require_relative '../spec_helper'
require 'core/config'
require 'pakyow/presenter/config/presenter'

describe 'configuration' do
  it 'registers presenter config' do
    expect(Pakyow::Config.presenter).to be_a(Pakyow::Config)
  end

  describe 'options' do
    let :opts do
      Pakyow::Config.presenter
        .instance_variable_get(:@defaults)
        .instance_variable_get(:@opts)
        .keys
    end

    describe 'require_route' do
      it 'is defined' do
        expect(opts).to include(:require_route)
      end

      it 'sets a default require_route value for development' do
        Pakyow::Config.env = :development
        expect(Pakyow::Config.presenter.require_route).to eq(false)
        Pakyow::Config.env = :test
      end

      it 'sets a default require_route value for production' do
        Pakyow::Config.env = :production
        expect(Pakyow::Config.presenter.require_route).to eq(true)
        Pakyow::Config.env = :test
      end
    end
  end
end

