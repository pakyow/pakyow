require 'support/helper'

class ApplicationActions < MiniTest::Unit::TestCase  
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
    Pakyow.app.router = MockRouter.new
    Pakyow.app.request = mock_request
    Pakyow.app.response = mock_response
    Pakyow.app.reroute(path)

    assert_equal :get, Pakyow.app.request.working_method
    assert_equal path, Pakyow.app.request.working_path
    assert Pakyow.app.router.rerouted
  end

  def test_application_can_be_rerouted_to_new_path_with_method
    reset

    path = '/foo/'
    method = :put
    Pakyow.app.router = MockRouter.new
    Pakyow.app.request = mock_request
    Pakyow.app.response = mock_response
    Pakyow.app.reroute(path, method)

    assert_equal method, Pakyow.app.request.working_method
    assert_equal path, Pakyow.app.request.working_path
    assert Pakyow.app.router.rerouted
  end

  def test_application_can_handle
    reset

    Pakyow.app.router = MockRouter.new
    Pakyow.app.handle(500)

    assert Pakyow.app.router.handled
  end

  def test_data_can_be_sent_from_application
    reset
    Pakyow.app.request = mock_request
    Pakyow.app.response = Response.new

    data = 'foo'
    
    catch(:halt) {
      Pakyow.app.send(data)
    }
    
    assert_equal([data], Pakyow.app.response.body)
    assert_equal('text/html', Pakyow.app.response.header['Content-Type'])
  end

  def test_data_can_be_sent_from_application_with_type
    reset
    Pakyow.app.request = mock_request
    Pakyow.app.response = Response.new

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
    Pakyow.app.request = mock_request
    Pakyow.app.response = Response.new

    path = File.join(File.dirname(__FILE__), 'support/foo.txt')

    data = File.open(path, 'r').read

    catch(:halt) {
      Pakyow.app.send(File.open(path, 'r'))
    }

    assert_equal([data], Pakyow.app.response.body)
    assert_equal('text/html', Pakyow.app.response.header['Content-Type'])
  end

  def test_file_can_be_sent_from_application_with_type
    reset
    Pakyow.app.request = mock_request
    Pakyow.app.response = Response.new

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
    Pakyow.app.request = mock_request
    Pakyow.app.response = Response.new

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
    TestApplication.reset(do_reset)
  end

  def app_test_path
    File.join('test', 'support', 'app.rb')
  end
end
