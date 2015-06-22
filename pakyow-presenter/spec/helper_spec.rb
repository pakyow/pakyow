require_relative 'support/helper'

describe Pakyow::Helpers do
  before(:each) do
    @context = MockPresenterContext.new
  end

  it 'delegates to presenter' do
    %w[store store= content view= partial template template= page page= path path= compose precompose!].each do |delegated|
      delegated = delegated.to_sym
      @context.send(delegated)
      expect(@context.presenter.called?(delegated)).to eq true
    end
  end

  it 'returns a context from a view' do
    expect(@context.view.is_a?(Pakyow::Presenter::ViewContext)).to eq true
  end

  it 'returns a context from a partial' do
    expect(@context.partial(:foo).is_a?(Pakyow::Presenter::ViewContext)).to eq true
  end

  it 'returns a context from a template' do
    expect(@context.template.is_a?(Pakyow::Presenter::ViewContext)).to eq true
  end

  it 'returns a context from a page' do
    expect(@context.page.is_a?(Pakyow::Presenter::ViewContext)).to eq true
  end

  it 'returns a context from a container' do
    expect(@context.container(:foo).is_a?(Pakyow::Presenter::ViewContext)).to eq true
  end
end
