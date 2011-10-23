require 'helper'

class ApplicationTest < Test::Unit::TestCase
  def test_application_path_is_set_when_inherited    
    assert(Pakyow::Configuration::App.application_path.include?(app_test_path))
  end
  
  def test_application_path_is_accurate_on_windows
    assert_equal(TestApplication.parse_path_from_caller("C:/test/test_application.rb:5"), 'C:/test/test_application.rb')
  end
  
  def test_application_runs
    app(true).run(:testing)
    assert_equal(true, app.running?)
  end
  
  def test_is_not_staged_when_running
    app(true).run(:testing)
    assert_not_same(true, app.staged?)
  end
  
  def test_application_runs_with_config
    app(true).run(:testing)
    assert_equal(false, Pakyow::Configuration::App.auto_reload)
    assert_equal(false, Pakyow::Configuration::App.errors_in_browser)
    
    app(true).run(:testing, :production)
    assert_equal(false, Pakyow::Configuration::App.auto_reload)
    assert_equal(false, Pakyow::Configuration::App.errors_in_browser)
    assert_equal(8000, Pakyow::Configuration::Server.port)
  end
  
  def test_application_does_not_run_when_staged
    app(true).stage(:testing)
    assert_not_equal(true, app.running?)
  end
  
  def test_detect_staged_application
    app(true).stage(:testing)
    assert_equal(true, app.staged?)
  end
  
  def test_application_is_staged_with_config
    app(true).stage(:testing)
    assert_equal(false, Pakyow::Configuration::App.auto_reload)
    assert_equal(false, Pakyow::Configuration::App.errors_in_browser)
    
    app(true).stage(:testing, :production)
    assert_equal(false, Pakyow::Configuration::App.auto_reload)
    assert_equal(false, Pakyow::Configuration::App.errors_in_browser)
    assert_equal(8000, Pakyow::Configuration::Server.port)
  end
  
  def test_base_config_is_returned
    assert_equal(Pakyow::Configuration::Base, app(true).config)
  end
  
  def test_configuration_is_stored
    app(true).stage(:testing)
    assert_not_nil(app.configurations[:testing])
  end
  
  def test_routes_are_stored
    app(true).stage(:testing)
    assert_not_nil(app.routes_proc)
  end
  
  def test_error_handler_is_created_with_controller_action_pair
    app(true).stage(:testing)
    assert_equal(:ApplicationController, app.error_handlers[404][:controller])
    assert_equal(:handle_404, app.error_handlers[404][:action])
  end
  
  def test_error_handler_is_created_with_block
    app(true).stage(:testing)
    assert_equal(Proc, app.error_handlers[500].class)
  end
  
  def test_app_is_set_when_initialized
    app(true)
    assert_nil(Pakyow.app)
    app(true).run(:testing)
    assert_equal(TestApplication, Pakyow.app.class)
  end
  
  def test_static_handler_is_created
    app(true).run(:testing)
    
    #TODO figure out how to test this now that static is middleware
    # assert_equal(Rack::File, Pakyow.app.static_handler.class)
    # assert_equal(Configuration::Base.app.public_dir, Pakyow.app.static_handler.root)
  end
  
  def test_presenter_is_set_if_available
    assert_nil(Pakyow.app.presenter)
    app(true).run(:presenter)
    assert_equal(TestPresenter, Pakyow.app.presenter.class)
  end
  
  def test_app_can_be_halted
    app(true).run(:testing)
    
    begin
      # halt! will halt execution if working properly
      Pakyow.app.halt!
    rescue
      @halted = true
    end
    
    assert_equal(true, @halted)
  end
  
  def test_static_handler_is_called_for_files_that_exist
    app(true).run(:testing)
    
    env = {
      'PATH_INFO' => 'application_test.rb'
    }
    
    Pakyow.app.call(env)
    
    #TODO figure out how to test this now that static is middleware
    # assert_equal(true, Pakyow.app.static)
  end
  
  def test_app_is_loaded_for_each_request_in_dev_mode_only
    # TODO
  end
  
  def test_cookies_are_available
    # TODO
  end
  
  def test_presenter_is_presented_if_set
    # TODO
  end
  
  def test_fact_is_asserted_and_matched
    # TODO
  end
  
  def test_response_body_is_set_if_presenter_and_no_interruption
    # TODO
  end
  
  def test_404_error_is_handled
    # TODO
  end
  
  def test_500_error_is_handled
    # TODO
  end
  
  def test_send_file
    # TODO
  end
  
  def test_send_data
    data = 'foo'
    type = 'text'
    file = 'foo.txt'
    
    begin
      Pakyow.app.send_data(data, type)
    rescue
      @halted = true
    end
    
    assert_equal(true, @halted)
    assert_equal([data], Pakyow.app.response.body)
    assert_equal(type, Pakyow.app.response.header['Content-Type'])
    
    # send with file name
    begin
      Pakyow.app.send_data(data, type, file)
    rescue
      @halted = true
    end
    
    assert_equal("attachment; filename=#{file}", Pakyow.app.response.header['Content-disposition'])
  end
  
  def test_redirect_to
    location = '/'
    
    begin
      Pakyow.app.redirect_to(location)
    rescue
      @halted = true
    end
    
    assert_equal(true, @halted)
    assert_equal(302, Pakyow.app.response.status)
    assert_equal(location, Pakyow.app.response.header['Location'])
  end
  
  def test_permanent_redirect_to
    location = '/'
    
    begin
      Pakyow.app.redirect_to(location, 301)
    rescue
      @halted = true
    end
    
    assert_equal(true, @halted)
    assert_equal(301, Pakyow.app.response.status)
    assert_equal(location, Pakyow.app.response.header['Location'])
  end
  
  def test_get_route_registration
    register_route(:get)
  end
  
  def test_post_route_registration
    register_route(:post)
  end
  
  def test_put_route_registration
    register_route(:put)
  end
  
  def test_delete_route_registration
    register_route(:delete)
  end
  
  def test_default_route_registration
    app(true).run(:testing)
    
    controller  = :TestController
    action      = :test_action
    block       = Proc.new {}
    
    Pakyow.app.default
    assert_nil(Pakyow.app.routes.last[:controller])
    assert_nil(Pakyow.app.routes.last[:action])
    assert_nil(Pakyow.app.routes.last[:block])
    Pakyow.app.routes = nil
    
    Pakyow.app.default(controller)
    assert_equal('/', Pakyow.app.routes.last[:route])
    assert_equal(controller, Pakyow.app.routes.last[:controller])
    assert_nil(Pakyow.app.routes.last[:action])
    assert_nil(Pakyow.app.routes.last[:block])
    Pakyow.app.routes = nil
    
    Pakyow.app.default(controller, action)
    assert_equal('/', Pakyow.app.routes.last[:route])
    assert_equal(controller, Pakyow.app.routes.last[:controller])
    assert_equal(action, Pakyow.app.routes.last[:action])
    assert_nil(Pakyow.app.routes.last[:block])
    Pakyow.app.routes = nil
    
    Pakyow.app.default {}
    assert_equal('/', Pakyow.app.routes.last[:route])
    assert_not_nil(Pakyow.app.routes.last[:block])
    Pakyow.app.routes = nil
  end
  
  def test_restful_actions
    Pakyow.app.restful_actions.each do |h|
      if h[:action] == :index
        assert_equal(:get, h[:method])
        assert_nil(h[:url_suffix])
      elsif h[:action] == :show
        assert_equal(:get, h[:method])
        assert_equal(':id', h[:url_suffix])
      elsif h[:action] == :new
        assert_equal(:get, h[:method])
        assert_equal('new', h[:url_suffix])
      elsif h[:action] == :create
        assert_equal(:post, h[:method])
        assert_nil(h[:url_suffix])
      elsif h[:action] == :edit
        assert_equal(:get, h[:method])
        assert_equal('edit/:id', h[:url_suffix])
      elsif h[:action] == :update
        assert_equal(:put, h[:method])
        assert_equal(':id', h[:url_suffix])
      elsif h[:action] == :delete
        assert_equal(:delete, h[:method])
        assert_equal(':id', h[:url_suffix])
      end
    end
  end
  
  def test_restful_route_registration
    app(true).run(:testing)
    
    url         = 'test'
    controller  = :TestController
    model       = :TestModel
    
    Pakyow.app.restful(url, controller, model)
    
    Pakyow.app.routes.each do |route|
      assert_equal(controller, route[:controller])
      assert_nil(route[:block])
      
      opts = Pakyow.app.restful_options_for_action(route[:action])
      restful_url = url.dup
      restful_url = File.join(restful_url, opts[:url_suffix]) if opts[:url_suffix]
      assert_equal(restful_url, route[:route])      
      assert_equal(route[:method], opts[:method])
    end
  end
  
  def test_nested_restful_route_registration
    app(true).run(:testing)
    
    url         = 'test'
    controller  = :TestController
    model       = :TestModel
    
    nested_url        = 'nested'
    nested_controller = :NestedController
    nested_model      = :NestedModel
    
    Pakyow.app.restful(url, controller, model) do
      Pakyow.app.restful(nested_url, nested_controller, nested_model)
    end
    
    Pakyow.app.routes.each do |route|
      # Skip non-nested routes because we know those work from previous test
      next if route[:controller] == controller
      
      assert_equal(nested_controller, route[:controller])
      assert_nil(route[:block])
      
      opts = Pakyow.app.restful_options_for_action(route[:action])
      restful_url = nested_url.dup
      restful_url = File.join(url, ":#{StringUtils.underscore(model.to_s)}_id", restful_url)
      restful_url = File.join(restful_url, opts[:url_suffix]) if opts[:url_suffix]
      assert_equal(restful_url, route[:route])      
      assert_equal(route[:method], opts[:method])
    end
  end
  
  protected
  
  def app(do_reset = false)
    TestApplication.reset(do_reset)
  end
  
  def register_route(method)
    app(true).run(:testing)
    
    route       = '/'
    controller  = :TestController
    action      = :test_action
    block       = Proc.new {}
    
    Pakyow.app.send(method, route)
    assert_equal(route, Pakyow.app.routes.last[:route])
    assert_nil(Pakyow.app.routes.last[:controller])
    assert_nil(Pakyow.app.routes.last[:action])
    assert_nil(Pakyow.app.routes.last[:block])
    Pakyow.app.routes = nil
    
    Pakyow.app.send(method, route, controller)
    assert_equal(route, Pakyow.app.routes.last[:route])
    assert_equal(controller, Pakyow.app.routes.last[:controller])
    assert_nil(Pakyow.app.routes.last[:action])
    assert_nil(Pakyow.app.routes.last[:block])
    Pakyow.app.routes = nil
    
    Pakyow.app.send(method, route, controller, action)
    assert_equal(route, Pakyow.app.routes.last[:route])
    assert_equal(controller, Pakyow.app.routes.last[:controller])
    assert_equal(action, Pakyow.app.routes.last[:action])
    assert_nil(Pakyow.app.routes.last[:block])
    Pakyow.app.routes = nil
    
    Pakyow.app.send(method, route) {}
    assert_equal(route, Pakyow.app.routes.last[:route])
    assert_not_nil(Pakyow.app.routes.last[:block])
    Pakyow.app.routes = nil
  end
  
  def app_test_path
    File.join('test', 'test_application.rb')
  end
  
end
