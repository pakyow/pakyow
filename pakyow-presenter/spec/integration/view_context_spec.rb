require_relative 'support/int_helper'

RSpec.describe Pakyow::Presenter::ViewContext do
  let :view do
    double('view', bind: Pakyow::Presenter::View.new, foo: :bar)
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

  it 'returns the working view' do
    expect(view_context.instance_variable_get(:@view)).to eq(view)
  end

  it 'passes calls through to view' do
    expect(view).to receive(:foo)
    view_context.foo
  end

  context 'when called method returns a view' do
    it 'returns a new view context' do
      ret = view_context.bind({})
      expect(ret).to be_a(Pakyow::Presenter::ViewContext)
      expect(ret).not_to eq(view_context)
    end
  end

  context 'when called method returns a non-view' do
    it 'returns the value' do
      expect(view_context.foo).not_to eq(view_context)
    end
  end

  context 'when calling view methods that expect context' do
    %i(bind bind_with_index apply).each do |method|
      it "passes context to #{method}" do
        expect(view).to receive(method).with({}, hash_including(context: app_context))
        view_context.send(method, {}) {}
      end
    end
  end

  context 'when calling view methods that yield or exec views' do
    let :view_context do
      Pakyow::Presenter::ViewContext.new(Pakyow::Presenter::View.new, app_context)
    end

    describe '#with' do
      it 'yields context' do
        view_context.with do |ctx|
          expect(ctx).to be_a(Pakyow::Presenter::ViewContext)
        end
      end

      it 'execs in context' do
        ctx = nil
        view_context.with { ctx = self }
        expect(ctx).to be_a(Pakyow::Presenter::ViewContext)
      end
    end

    describe '#for' do
      it 'yields context' do
        view_context.for({}) do |ctx, _|
          expect(ctx).to be_a(Pakyow::Presenter::ViewContext)
        end
      end

      it 'execs in context' do
        ctx = nil
        view_context.for({}) { |_| ctx = self }
        expect(ctx).to be_a(Pakyow::Presenter::ViewContext)
      end
    end

    describe '#for_with_index' do
      it 'yields context' do
        view_context.for_with_index({}) do |ctx, _, _|
          expect(ctx).to be_a(Pakyow::Presenter::ViewContext)
        end
      end

      it 'execs in context' do
        ctx = nil
        view_context.for_with_index({}) { |_, _| ctx = self }
        expect(ctx).to be_a(Pakyow::Presenter::ViewContext)
      end
    end

    describe '#repeat' do
      it 'yields context' do
        view_context.repeat({}) do |ctx, _|
          expect(ctx).to be_a(Pakyow::Presenter::ViewContext)
        end
      end

      it 'execs in context' do
        ctx = nil
        view_context.repeat({}) { |_| ctx = self }
        expect(ctx).to be_a(Pakyow::Presenter::ViewContext)
      end
    end

    describe '#repeat_with_index' do
      it 'yields context' do
        view_context.repeat_with_index({}) do |ctx, _, _|
          expect(ctx).to be_a(Pakyow::Presenter::ViewContext)
        end
      end

      it 'execs in context' do
        ctx = nil
        view_context.repeat_with_index({}) { |_, _| ctx = self }
        expect(ctx).to be_a(Pakyow::Presenter::ViewContext)
      end
    end

    describe '#bind' do
      it 'yields context' do
        view_context.bind({}) do |ctx, _|
          expect(ctx).to be_a(Pakyow::Presenter::ViewContext)
        end
      end

      it 'execs in context' do
        ctx = nil
        view_context.bind({}) { |_| ctx = self }
        expect(ctx).to be_a(Pakyow::Presenter::ViewContext)
      end
    end

    describe '#bind_with_index' do
      it 'yields context' do
        view_context.bind_with_index({}) do |ctx, _, _|
          expect(ctx).to be_a(Pakyow::Presenter::ViewContext)
        end
      end

      it 'execs in context' do
        ctx = nil
        view_context.bind_with_index({}) { |_, _| ctx = self }
        expect(ctx).to be_a(Pakyow::Presenter::ViewContext)
      end
    end

    describe '#apply' do
      it 'yields context' do
        view_context.apply({}) do |ctx, _|
          expect(ctx).to be_a(Pakyow::Presenter::ViewContext)
        end
      end

      it 'execs in context' do
        ctx = nil
        view_context.apply({}) { |_| ctx = self }
        expect(ctx).to be_a(Pakyow::Presenter::ViewContext)
      end
    end
  end
end
