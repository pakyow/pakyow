require 'rubygems'
require 'minitest'
require 'minitest/unit'
require 'minitest/autorun'
require 'pp'

require File.expand_path('../../../../pakyow-core/lib/pakyow-core', __FILE__)
require File.expand_path('../../../lib/pakyow-presenter', __FILE__)

require_relative 'test_application'

def capture_stdout(&block)
  original_stdout = $stdout
  $stdout = fake = StringIO.new
  Pakyow::Log.reopen
  begin
    yield
  ensure
    $stdout = original_stdout
    Pakyow::Log.reopen
  end
 fake.string
end
