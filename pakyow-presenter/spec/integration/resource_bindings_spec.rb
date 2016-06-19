require_relative 'support/int_helper'
require_relative 'support/helpers/req_res_helpers'

describe 'defining a resource' do
  include ReqResHelpers
  include SetupHelper

  before :each do
    setup

    app.resource :test, "tests" do
      list do; end
    end

    app.presenter.load
  end

  after do
    teardown
  end

  let :app do
    Pakyow.app
  end

  it 'creates a binding set for the resource name' do
    scope = Pakyow::Presenter::Binder.instance.sets[:test].scopes[:test]
    expect(scope).not_to be_nil
  end

  describe 'the binding set block' do
    let :binding_set_block do
      app.bindings[:test]
    end

    it 'exists' do
      expect(binding_set_block).to be_kind_of Proc
    end

    context 'when evaluated' do
      let :set do
        Pakyow::Presenter::BinderSet.new(&binding_set_block)
      end

      it 'creates restful bindings with with scope for resource name' do
        expect(set.has_prop?(:test, :_root, {})).to be true
      end
    end
  end
end
