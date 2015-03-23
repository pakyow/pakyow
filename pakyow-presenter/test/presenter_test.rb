require_relative 'support/helper'

class PresenterTest < Minitest::Test
  include ReqResHelpers

  def setup
    capture_stdout do
      @store = :test
      Pakyow::App.stage(:test)
      @presenter = Pakyow.app.presenter
      @path = '/'
      @presenter.prepare_with_context(AppContext.new(mock_request(@path)))
    end
  end

  def teardown
    # Do nothing
  end

  def test_view_is_built_for_request
    assert_instance_of Pakyow::Presenter::ViewComposer, @presenter.view
    assert_instance_of Pakyow::Presenter::View, @presenter.view.composed

    page = @presenter.store.page(@path)
    template = @presenter.store.template(@path)
    view = @presenter.store.view(@path)

    assert_equal view, @presenter.view.composed
    assert_equal page, @presenter.composer.page
    assert_equal template, @presenter.composer.template
  end


  def test_view_content_is_returned
    view = @presenter.store.view(@path)
    assert_equal view.to_html, @presenter.content
  end

  def test_path_can_be_set_and_retrieved
    capture_stdout do
      path = 'multi'
      @presenter.path = path
      assert_equal path, @presenter.path
    end
  end

  def test_view_is_rebuilt_when_path_set
    capture_stdout do
      original_view = @presenter.view
      assert_same original_view, @presenter.view

      @presenter.path = 'multi'
      refute_same original_view, @presenter.view
      assert_equal Pakyow::Presenter::ViewComposer, @presenter.view.class
    end
  end

  def test_store_can_be_changed
    original_store = @presenter.store
    @presenter.store = :test
    refute_same original_store, @presenter.store
  end

  def test_template_for_route_is_accessible
    assert_equal @presenter.store.template(@path), @presenter.composer.template
  end

  def test_template_instance_can_be_set_and_retrieved
    capture_stdout do
      template = @presenter.store.template(:multi)
      @presenter.template = template
      assert_same template, @presenter.composer.template
    end
  end

  def test_template_can_be_set_by_name_and_retrieved
    capture_stdout do
      name = :multi
      template = @presenter.store.template(name)
      @presenter.template = name
      assert_equal template, @presenter.composer.template
    end
  end

  def test_current_template_is_used
    capture_stdout do
      @presenter.template = :multi
      assert_equal 'multi', @presenter.view.composed.title
    end
  end

  def test_default_page_for_route_is_accessible
    assert_equal @presenter.store.page(@path), @presenter.composer.page
  end

  def test_page_can_by_set_and_retrieved
    page = @presenter.store.page('sub')
    @presenter.page = page
    assert_equal page, @presenter.composer.page
  end

  def test_current_page_is_used
    page = @presenter.store.page('sub')
    @presenter.page = page
    assert_equal page.content(:default).to_s.strip, str_to_doc(@presenter.view.composed.to_html).css('body').inner_text.strip
  end

  def test_presented_is_correct_value
    assert @presenter.presented?

    capture_stdout do
      @presenter.prepare_with_context(AppContext.new(mock_request('/fail')))
    end

    refute @presenter.presented?
  end

  def test_views_are_cached
    file = 'test/support/views/index.html'
    new_content = 'reloaded'

    original_content = File.open(file, 'r').read
    File.open(file, 'w') { |f| f.write(new_content) }

    capture_stdout do
      assert_equal(original_content.strip, str_to_doc(@presenter.view.composed.to_html).css('body').inner_text.strip)
    end
  ensure
    File.open(file, 'w') { |f| f.write(original_content) }

    capture_stdout do
      @presenter.load
    end
  end

  def test_views_are_reloaded
    file = 'test/support/views/index.html'
    new_content = 'reloaded'

    original_content = File.open(file, 'r').read

    File.open(file, 'w') { |f| f.write(new_content) }

    capture_stdout do
      @presenter.load
      setup

      assert_equal(new_content, str_to_doc(@presenter.view.composed.to_html).css('body').children.to_html.strip)
    end
  ensure
    File.open(file, 'w') { |f| f.write(original_content) }

    capture_stdout do
      @presenter.load
    end
  end

  def test_composes_from_current_context
    path = 'composer'
    @presenter.prepare_with_context(AppContext.new(mock_request(path)))
    assert_equal @presenter.store.view(path), @presenter.compose.view
  end

  def test_sets_view_from_view_composer
    path = 'composer'
    comparison_view = @presenter.store.view(path)

    @presenter.compose_at(path)

    assert_equal comparison_view, @presenter.view.composed
  end

  def test_can_override_view
    @presenter.view = View.new('foo')
    assert_equal 'foo', @presenter.view.to_html
  end
  
  def test_precomposition
    @presenter.prepare_with_context(AppContext.new(mock_request('composer')))
    composer = @presenter.composer
    
    @presenter.precompose!
    assert_equal composer.view, @presenter.view
  end

  def test_partials_can_be_set
    @presenter.view.partials = { partial: 'partial1' }
    partial = Partial.load('test/support/views/_partial1.html')
    assert_equal partial, @presenter.view.partial(:partial)
  end
end
