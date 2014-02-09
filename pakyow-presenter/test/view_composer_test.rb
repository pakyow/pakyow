require_relative 'support/helper'

describe ViewComposer do
  before do
    capture_stdout do
      @store = ViewStore.new('test/support/views')
    end
  end

  it "composes at a path" do
    compose_at('/').view.must_equal view_for(:pakyow, 'index.html')
  end

  it "composes with a page" do
    compose(page: 'composer').view.must_equal view_for(:composer, 'composer/index.html')
  end

  it "fails to compose without a path or page" do
    lambda { compose({}) }.must_raise(ArgumentError)
  end

  it "composes at a path with overridden template" do
    capture_stdout do
      compose_at('composer', template: :sub).view.must_equal view_for(:sub, 'composer/index.html')
    end
  end

  it "composes at a path with overridden page" do
    capture_stdout do
      compose_at('composer', page: 'multi/index').view.must_equal view_for(:multi, 'multi/index.html')
    end
  end

  it "composes at a path with overridden template, page, and includes" do
    capture_stdout do
      compose_at('/', 
        template: :sub, 
        page: 'composer',
        includes: {
          one: 'composer/partials/one'
        }
      ).view.must_equal view_for(:sub, 'composer/index.html', { one: 'composer/partials/_one.html'})
    end
  end

  it "composes with method chaining" do
    capture_stdout do
      compose_at('/').template(:multi).view.must_equal view_for(:multi, 'index.html')
    end
  end

  it "composes with a block" do
    capture_stdout do
      compose_at('/') {
        template(:multi)
      }.view.must_equal view_for(:multi, 'index.html')
    end
  end

  it "exposes template" do
    composer = compose_at('/')
    assert_instance_of Template, composer.template
  end

  it "exposes page" do
    composer = compose_at('/')
    assert_instance_of Page, composer.page
  end

  it "exposes partials" do
    composer = compose_at('/partial')
    assert_instance_of Partial, composer.partial(:partial1)
  end

  def compose(opts, &block)
    ViewComposer.from_path(@store, nil, opts, &block)
  end

  def compose_at(path, opts = {}, &block)
    ViewComposer.from_path(@store, path, opts, &block)
  end

  def compose_with_context(context, opts = {}, &block)
    ViewComposer.from_context(@store, context.request.path, opts, &block)
  end

  def view_for(template_name, page_path, partials = {})
    template = @store.template(template_name)
    page = Page.load(@store.expand_path(page_path))

    partials = Hash[partials.map { |name, path|
      [name, Partial.load(@store.expand_path(path))]
    }]
    
    return template.build(page).includes(partials)
  end

end
