require 'support/helper'

describe Pakyow::Presenter::ViewContext do
  let :view do
    double('view', bind: View.new, foo: :bar)
  end

  let :app_context do
    double('app_context')
  end

  let :view_context do
    Pakyow::Presenter::ViewContext.new(view, app_context)
  end

  it 'sets view on initialization' do
    expect(view_context.instance_variable_get(:@view)).to eq(view)
  end

  it 'sets context on initialization' do
    expect(view_context.instance_variable_get(:@context)).to eq(app_context)
  end

  %i(bind bind_with_index apply).each do |method|
    it "passes context to #{method}" do
      expect(view).to receive(method).with({}, hash_including(ctx: app_context))
      view_context.send(method, {}) {}
    end
  end

  it 'returns the working view' do
    expect(view_context.working).to eq(view)
  end

  it 'passes calls through to view' do
    expect(view).to receive(:foo)
    view_context.foo
  end

  context 'when called method returns a view' do
    it 'updates the working view' do
      original_working = view_context.working
      view_context.bind({})

      expect(view_context.working).not_to eq(original_working)
      expect(view_context.working).to be_a(Pakyow::Presenter::View)
    end

    it 'returns self' do
      expect(view_context.bind({})).to eq(view_context)
    end
  end

  context 'when called method returns a non-view' do
    it 'does not update the working view' do
      original_working = view_context.working
      view_context.foo
      expect(view_context.working).to eq(original_working)
    end

    it 'returns the value' do
      expect(view_context.foo).not_to eq(view_context)
    end
  end
end
