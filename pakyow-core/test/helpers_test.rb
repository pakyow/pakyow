require 'support/helper'

class HelpersTest < Minitest::Test
  include Pakyow::Helpers

  def setup
    Pakyow::App.stage(:test)
    Pakyow.app.context = Context.new(mock_request, mock_response)
  end

  def test_app_returned
    assert_same Pakyow.app.class, Pakyow::App
  end

  def test_app_request_returned
    r = :test
    Pakyow.app.context = Context.new(r)
    assert_same r, Pakyow.app.request
    assert_same r, Pakyow.app.req
  end

  def test_app_response_returned
    r = :test
    Pakyow.app.context = Context.new(nil, r)
    assert_same r, Pakyow.app.response
    assert_same r, Pakyow.app.res
  end

  def test_router_lookup_returned
    assert Pakyow.app.router.is_a?(Pakyow::RouteLookup)
  end

  def test_params_returned
    Pakyow.app.context = Context.new(mock_request)
    assert_same Pakyow.app.params, Pakyow.app.params
  end

  def test_session_returned
    Pakyow.app.context = Context.new(mock_request)
    assert_equal Pakyow.app.session, Pakyow.app.request.session
  end

  def test_cookies_returned
    Pakyow.app.context = Context.new(mock_request)
    assert_same Pakyow.app.cookies, Pakyow.app.cookies
  end

  def test_app_helpers_are_included_in_app
    assert Pakyow::App.ancestors.include?(Pakyow::AppHelpers)
  end
end
