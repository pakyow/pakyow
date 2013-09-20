require_relative 'support/helper'

class PresenterTest < Minitest::Test

  def setup
    capture_stdout do
      @store = :test
      Pakyow::App.stage(:test)
      @presenter = Pakyow.app.presenter
      @path = '/'
      @presenter.prepare_for_request(request(@path))
    end
  end

  def teardown
    # Do nothing
  end

  def test_view_is_built_for_request
    assert_instance_of Pakyow::Presenter::View, @presenter.view

    page = @presenter.store.page(@path)
    template = @presenter.store.template(@path)
    view = @presenter.store.view(@path)

    assert_equal page, @presenter.page
    assert_equal template, @presenter.template
    assert_equal view.to_html, @presenter.view.to_html
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
      assert_equal Pakyow::Presenter::View, @presenter.view.class
    end
  end

  def test_store_can_be_changed
    @presenter.store = :test
    assert_equal 'switch', @presenter.view.title, 'Template not updated for new store'
    assert_equal 'switch', @presenter.view.doc.css('body').inner_text.strip, 'Page not updated for new store'
  end

  def test_template_for_route_is_accessible
    assert_same @presenter.store.template(@path), @presenter.template
  end

  def test_template_instance_can_be_set_and_retrieved
    capture_stdout do
      template = @presenter.store.template(:multi)
      @presenter.template = template
      assert_same template, @presenter.template
    end
  end

  def test_template_can_be_set_by_name_and_retrieved
    capture_stdout do
      name = :multi
      template = @presenter.store.template(name)
      @presenter.template = name
      assert_same template, @presenter.template
    end
  end

  def test_current_template_is_used
    capture_stdout do
      @presenter.template = :multi
      assert_equal 'multi', @presenter.view.title
    end
  end

  def test_default_page_for_route_is_accessible
    assert_equal @presenter.store.page(@path), @presenter.page
  end

  def test_page_can_by_set_and_retrieved
    page = @presenter.store.page('sub')
    @presenter.page = page
    assert_equal page, @presenter.page
  end

  def test_current_page_is_used
    page = @presenter.store.page('sub')
    @presenter.page = page
    assert_equal page.content(:default).strip, @presenter.view.doc.css('body').inner_text.strip
  end

  def test_presented_is_correct_value
    assert @presenter.presented?

    capture_stdout do
      @presenter.prepare_for_request(request('/fail'))
    end

    refute @presenter.presented?
  end

  def test_partial_can_be_retrieved_for_path
    name = :partial1
    partial = @presenter.store.partial(@presenter.path, name)
    assert_same partial, @presenter.partial(name)
  end

  def test_views_are_cached
    file = 'test/support/views/index.html'
    new_content = 'reloaded'

    original_content = File.open(file, 'r').read
    File.open(file, 'w') { |f| f.write(new_content) }

    capture_stdout do
      assert_equal(original_content.strip, @presenter.view.doc.css('body').inner_text.strip)
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

      assert_equal(new_content, @presenter.view.doc.css('body').children.to_html.strip)
    end
  ensure
    File.open(file, 'w') { |f| f.write(original_content) }

    capture_stdout do
      @presenter.load
    end
  end

  private

  def request(path = '/', method = 'GET')
    req = Pakyow::Request.new({ "PATH_INFO" => path, "REQUEST_METHOD" => method, "rack.input" => {} })
    req.path = path
    req
  end

end
