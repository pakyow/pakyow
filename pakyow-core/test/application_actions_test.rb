require 'support/helper'

class ApplicationActions < Minitest::Test
  def test_application_can_be_halted
    reset

    begin
      Pakyow.app.halt
    rescue
      @halted = true
    end

    assert_equal(true, @halted)
  end

  def test_application_can_be_redirected
    reset
    location = '/'
    begin
      Pakyow.app.redirect(location)
    rescue
    end

    assert_equal(302, Pakyow.app.response.status)
    assert_equal(location, Pakyow.app.response.header['Location'])
  end

  def test_application_redirect_issues_route_lookup
    reset
    
    begin
      Pakyow.app.redirect(:redirect_route)
    rescue
    end

    assert_equal(302, Pakyow.app.response.status)
    assert_equal('/redirect', Pakyow.app.response.header['Location'])
  end

  def test_application_redirect_respects_status
    reset
    location = '/'
    begin
      Pakyow.app.redirect(location, 301)
    rescue
    end

    assert_equal(301, Pakyow.app.response.status)
    assert_equal(location, Pakyow.app.response.header['Location'])
  end

  def test_application_redirect_halts
    reset

    begin
      Pakyow.app.redirect('/')
    rescue
      @halted = true
    end

    assert_equal(true, @halted)
  end

  def test_application_can_be_rerouted_to_new_path
    reset

    path = '/foo/'
    router = MockRouter.new
    Pakyow.app.router = router
    Pakyow.app.response = mock_response
    Pakyow.app.request = mock_request
    Pakyow.app.reroute(path)

    assert_equal :get, Pakyow.app.request.method
    assert_equal path, Pakyow.app.request.path
    assert router.rerouted
  end

  def test_application_can_be_rerouted_to_new_path_with_method
    reset

    path = '/foo/'
    method = :put
    router = MockRouter.new
    Pakyow.app.router = router
    Pakyow.app.response = mock_response
    Pakyow.app.request = mock_request
    Pakyow.app.reroute(path, method)

    assert_equal method, Pakyow.app.request.method
    assert_equal path, Pakyow.app.request.path
    assert router.rerouted
  end

  def test_application_can_handle
    reset

    router = MockRouter.new
    Pakyow.app.router = router
    Pakyow.app.handle(500)

    assert router.handled
  end

  def test_data_can_be_sent_from_application
    reset
    Pakyow.app.response = mock_response
    Pakyow.app.request = mock_request

    data = 'foo'

    catch(:halt) {
      Pakyow.app.send(data)
    }

    assert_equal([data], Pakyow.app.response.body)
    assert_equal('text/html', Pakyow.app.response.header['Content-Type'])
  end

  def test_data_can_be_sent_from_application_with_type
    reset
    Pakyow.app.response = mock_response
    Pakyow.app.request = mock_request

    data = 'foo'
    type = 'text'

    catch(:halt) {
      Pakyow.app.send(data, type)
    }

    assert_equal([data], Pakyow.app.response.body)
    assert_equal(type, Pakyow.app.response.header['Content-Type'])
  end

  def test_file_can_be_sent_from_application
    reset
    Pakyow.app.response = mock_response
    Pakyow.app.request = mock_request

    path = File.join(File.dirname(__FILE__), 'support/foo.txt')

    data = File.open(path, 'r').read

    catch(:halt) {
      Pakyow.app.send(File.open(path, 'r'))
    }

    assert_equal([data], Pakyow.app.response.body)
    assert_equal('text/plain', Pakyow.app.response.header['Content-Type'])
  end

  def test_file_can_be_sent_from_application_with_type
    reset
    Pakyow.app.response = mock_response
    Pakyow.app.request = mock_request

    type = 'text/plain'
    path = File.join(File.dirname(__FILE__), 'support/foo.txt')

    data = File.open(path, 'r').read

    catch(:halt) {
      Pakyow.app.send(File.open(path, 'r'), type)
    }

    assert_equal([data], Pakyow.app.response.body)
    assert_equal(type, Pakyow.app.response.header['Content-Type'])
  end

  def test_file_can_be_sent_from_application_with_type_as_attachment
    reset
    Pakyow.app.response = mock_response
    Pakyow.app.request = mock_request

    as = 'foo.txt'
    type = 'text/plain'
    path = File.join(File.dirname(__FILE__), 'support/foo.txt')

    data = File.open(path, 'r').read

    catch(:halt) {
      Pakyow.app.send(File.open(path, 'r'), type, as)
    }

    assert_equal([data], Pakyow.app.response.body)
    assert_equal(type, Pakyow.app.response.header['Content-Type'])
    assert_equal("attachment; filename=#{as}", Pakyow.app.response.header['Content-disposition'])
  end

  protected

  def reset
    app(true).run(:test)
  end

  def app(do_reset = false)
    Pakyow::App.reset(do_reset)
  end

  def app_test_path
    File.join('test', 'support', 'app.rb')
  end
end
