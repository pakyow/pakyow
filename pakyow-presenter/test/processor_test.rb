require 'support/helper'

class ProcessorTest < MiniTest::Unit::TestCase

  def setup
    @view_store = :test
    Pakyow::App.stage(:test)
    Pakyow.app.presenter.view_store = @view_store
  end

  def teardown
    # Do nothing
  end

  def test_processor_processes
    v = View.at_path("processor", @view_store)
    assert_equal v.container(:main)[0].html, 'foobar'
  end

  def test_processor_processes_multiple_formats
    v = View.at_path("processor2", @view_store)
    assert_equal v.container(:main)[0].html, 'foobar'
  end

end