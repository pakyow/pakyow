require 'test/helper'

class ConfigurationTest < Test::Unit::TestCase
  def test_server_configuration_is_returned
    assert_equal(Configuration::Server, Pakyow::Configuration::Base.server)
  end
  
  def test_server_configuration_defaults
    assert_equal(3000, Pakyow::Configuration::Server.port)
    assert_equal('0.0.0.0', Pakyow::Configuration::Server.host)
  end
  
  def test_app_configuration_defaults
    assert_equal(:index, Pakyow::Configuration::App.default_action)
    assert_equal(false, Pakyow::Configuration::App.ignore_routes)
  end
end
