require_relative 'support/helper'

describe ViewComposer do
  before do
    capture_stdout do
      @store = ViewStore.new('test/support/views')
    end
  end

  it "composes a template at a path" do
    compose {
      template(:pakyow).at('/')
    }.view.html.must_equal html_for(:pakyow, 'index.html')
  end

  it "supports method chaining" do
    compose.template(:pakyow).at('/').view.html.must_equal html_for(:pakyow, 'index.html')
  end

  it "composes with default template" do
    compose {
      at('/')
    }.view.html.must_equal html_for(:pakyow, 'index.html')
  end

  it "composes with context" do
    compose_with_context(Context.new(mock_request('/'))).view.html.must_equal html_for(:pakyow, 'index.html')
  end

  it "includes partials from map" do
    compose {
      at('composer').includes(
        template: 'composer/partials/template',
        one: 'composer/partials/one',
      )
    }.view.html.must_equal html_for(:partialized, 'composer/index.html', { 
      template: 'composer/partials/_template.html', 
      one: 'composer/partials/_one.html',
      two: 'composer/_two.html',
    })
  end

  def compose(&block)
    ViewComposer.new(@store, &block)
  end

  def compose_with_context(context, &block)
    ViewComposer.new(@store, context, &block)
  end

  def html_for(template_name, page_path, partials = {})
    template = @store.template(template_name)
    page = Page.load(@store.expand_path(page_path))

    partials = Hash[partials.map { |name, path|
      [name, Partial.load(@store.expand_path(path))]
    }]
    
    return template.build(page).includes(partials).html
  end

end
