require 'support/helper'

require 'stringio'

class LogTest < MiniTest::Unit::TestCase
  def setup
    @text = 'foo'
  end

  def teardown
    FileUtils.rm(file) if File.exists?(file)
  end

  def test_log_to_console
    old = $stdout
    $stdout = StringIO.new
    Pakyow::Log.reopen
    Log.enter(@text)
    
    assert_equal @text, $stdout.string.strip

    $stdout = old
  end
  
  def test_log_to_file
    Configuration::Base.app.log_dir = path
    Pakyow::Log.reopen
    Log.enter(@text)
    Log.close

    assert       File.exists?(file)
    assert_equal @text, File.new(file).read.strip
  end

  private

  def file
    File.join(path, 'requests.log')
  end

  def path
    File.join(Dir.pwd, 'test')
  end
end
