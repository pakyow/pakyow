require 'support/helper'

class HelpersTest < MiniTest::Unit::TestCase
  def setup
    TestApplication.stage(:test)
    @h = TestHelpers.new
  end

  def test_app_returned
    assert_same Pakyow.app, @h.app
  end

  def test_app_request_returned
    r = :test
    Pakyow.app.request = r
    assert_same @h.request, r
  end

  def test_app_response_returned
    r = :test
    Pakyow.app.response = r
    assert_same @h.response, r
  end

  def test_router_lookup_returned
    assert @h.router.is_a?(Pakyow::RouteLookup)
  end

  def test_params_returned
    Pakyow.app.request = mock_request
    assert_same @h.params, Pakyow.app.params
  end

  def test_session_returned
    Pakyow.app.request = mock_request
    assert_equal @h.session, Pakyow.app.request.session
  end

  def test_cookies_returned
    Pakyow.app.request = mock_request
    assert_same @h.cookies, Pakyow.app.cookies
  end  

  def test_general_helpers_are_included_in_helpers
    assert Pakyow::Helpers.ancestors.include?(Pakyow::GeneralHelpers)
  end
end

class TestHelpers
  include Helpers
end
