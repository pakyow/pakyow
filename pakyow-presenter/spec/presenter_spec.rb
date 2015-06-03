require_relative 'support/helper'
include SetupHelper

describe Presenter do
  include ReqResHelpers

  before do
    Pakyow::Config.presenter.view_doc_class = Pakyow::Presenter::StringDoc
    @store = :test
    Pakyow::App.stage(:test)
    @presenter = Pakyow.app.presenter
    @path = '/'
    @presenter.prepare_with_context(AppContext.new(mock_request(@path)))
  end

  after do
    teardown
  end

  context 'test view' do
    before do
      reset_index_contents
    end

    it 'is built for request' do
      expect(@presenter.view).to be_a Pakyow::Presenter::ViewComposer
      expect(@presenter.view.composed).to be_a View

      page = @presenter.store.page(@path)
      template = @presenter.store.template(@path)
      view = @presenter.store.view(@path)

      expect(view).to eq @presenter.view.composed
      expect(page).to eq @presenter.composer.page
      expect(template).to eq @presenter.composer.template
    end

    it 'returns content' do
      view = @presenter.store.view(@path)
      expect(view.to_html).to eq @presenter.content
    end

    it 'is rebuilt when path is set' do
      original_view = @presenter.view
      expect(original_view).to eq @presenter.view

      @presenter.path = 'multi'
      expect(original_view).to_not eq @presenter.view
      expect(Pakyow::Presenter::ViewComposer).to eq @presenter.view.class
    end

    it 'is cached' do
      file = File.join(VIEW_PATH, 'index.html')
      new_content = 'reloaded'
      original_content = File.open(file, 'r').read
      File.open(file, 'w') { |f| f.write(new_content) }
      composed = str_to_doc(@presenter.view.composed.to_html).css('body').inner_text.strip

      expect(original_content.strip).to eq composed
    end

    it 'is reloaded' do
      file = File.join(VIEW_PATH, 'index.html')
      new_content = 'reloaded'
      File.open(file, 'w') { |f| f.write(new_content) }
      @presenter.load
      setup
      composed = str_to_doc(@presenter.view.composed.to_html).css('body').children.to_html.strip

      expect(new_content).to eq composed
    end

    it 'is set from view composer' do
      path = 'composer'
      comparison_view = @presenter.store.view(path)
      @presenter.compose_at(path)

      expect(comparison_view).to eq @presenter.view.composed
    end

    it 'can be overidden' do
      @presenter.view = View.new('foo')
      expect('foo').to eq @presenter.view.to_html
    end

    it 'can be tested for existence' do
      expect(@presenter.view?('/')).to be true
      expect(@presenter.view?('/fail')).to be false
    end
  end

  context 'test path' do
    it 'can be set and retrieved' do
      path = 'multi'
      @presenter.path = path
      expect(path).to eq @presenter.path
    end
  end

  context 'test store' do
    it 'can be changed' do
      original_store = @presenter.store
      @presenter.store = :test
      expect(original_store).to_not eq @presenter.store
    end
  end

  context 'test template' do
    it 'for route is accessible' do
      expect(@presenter.store.template(@path)).to eq @presenter.composer.template
    end

    it 'instance can be set and retrieved' do
      template = @presenter.store.template(:multi)
      @presenter.template = template
      expect(template).to eq @presenter.composer.template
    end

    it 'can be set by name and retrieved' do
      name = :multi
      template = @presenter.store.template(name)
      @presenter.template = name
      expect(template).to eq @presenter.composer.template
    end

    it 'uses current template' do
      @presenter.template = :multi
      expect('multi').to eq @presenter.view.composed.title
    end
  end

  context 'test page' do
    it 'has a route accessible for default page' do
      expect(@presenter.store.page(@path)).to eq @presenter.composer.page
    end

    it 'can by set and retrieved' do
      page = @presenter.store.page('sub')
      @presenter.page = page
      expect(page).to eq @presenter.composer.page
    end

    it 'uses current page' do
      page = @presenter.store.page('sub')
      @presenter.page = page
      composed = str_to_doc(@presenter.view.composed.to_html).css('body').inner_text.strip

      expect(page.content(:default).to_s.strip).to eq composed
    end
  end

  context 'test presented' do
    it 'has correct value' do
      expect(@presenter.presented?).to be true

      @presenter.prepare_with_context(AppContext.new(mock_request('/fail')))

      expect(@presenter.presented?).to be false
    end
  end

  context 'test composer' do
    it 'composes from current context' do
      path = 'composer'
      @presenter.prepare_with_context(AppContext.new(mock_request(path)))
      expect(@presenter.store.view(path)).to eq @presenter.compose.view
    end

    it 'can precompose' do
      @presenter.prepare_with_context(AppContext.new(mock_request('composer')))
      composer = @presenter.composer

      @presenter.precompose!
      expect(composer.view).to eq @presenter.view
    end
  end

  context 'test partial' do
    it 'can be set' do
      @presenter.view.partials = { partial: 'partial1' }
      partial = Partial.load(File.join(VIEW_PATH, '_partial1.html'))
      expect(partial).to eq @presenter.view.partial(:partial)
    end
  end
end
