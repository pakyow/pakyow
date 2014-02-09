require_relative 'support/helper'

class ProcessorTest < Minitest::Test

  def setup
    capture_stdout do
      Pakyow::App.stage(:test)
    end
  end

  def teardown
    # Do nothing
  end

  def test_processor_processes
    v = Pakyow.app.presenter.store.view("processor")
    assert_equal 'foobar', v.doc.css('body').inner_text.strip
  end

  def test_processor_processes_multiple_formats
    v = Pakyow.app.presenter.store.view("processor2")
    assert_equal 'foobar', v.doc.css('body').inner_text.strip
  end

end
