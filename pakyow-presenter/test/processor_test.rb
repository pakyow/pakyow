require_relative 'support/helper'

class ProcessorTest < Minitest::Test
  include ReqResHelpers

  def setup
    capture_stdout do
      Pakyow::App.stage(:test)
      Pakyow.app.presenter.prepare_with_context(AppContext.new(mock_request('/')))
    end
  end

  def teardown
    # Do nothing
  end

  def test_processor_processes
    v = Pakyow.app.presenter.store.view("processor")
    assert_equal 'foo', str_to_doc(v.to_html).css('body').inner_text.strip
  end

  def test_processor_processes_multiple_formats
    v = Pakyow.app.presenter.store.view("processor2")
    assert_equal 'foo', str_to_doc(v.to_html).css('body').inner_text.strip
  end

end
