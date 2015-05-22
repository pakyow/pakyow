require 'support/helper'
include TestFns


describe 'Route Mixin' do
  before do
    Pakyow::App.stage(:test)
  end

  it 'errors when included in class' do
    expect{ TestClass.instance_exec { include Pakyow::Routes } }.to raise_error StandardError
  end

  it 'calls are forwarded to route eval' do
    original_eval = TestFns.instance_variable_get(:@route_eval)
    eval = MockEval.new
    TestFns.instance_variable_set(:@route_eval, eval)

    %w(fn default get put post delete handler group namespace template action expand).each do |call|
      TestFns.send(call.to_sym)
      expect(eval.called?(call.to_sym)).to eq true
    end
    TestFns.instance_variable_set(:@route_eval, original_eval)
  end

  it 'test route modules can be included in set' do
    @fns = {
      foo: lambda { |i| puts i }
    }

    TestFns.fn :foo, &@fns[:foo]

    Pakyow::App.routes :test do
      include TestFns
      include Pakyow::Routes::Restful
    end

    Pakyow.app.reload

    expect(@fns[:foo]).to eq Pakyow::Router.instance.sets[:test].fn(:foo)
  end
end
