require 'rubygems'
require 'rspec'
require 'pry'
require 'pp'

require File.expand_path('../../../../pakyow-core/lib/pakyow-core', __FILE__)
require File.expand_path('../../../lib/pakyow-presenter', __FILE__)

def capture_stdout(&block)
  original_stdout = $stdout
  $stdout = fake = StringIO.new
  Pakyow.configure_logger
  begin
    yield
  ensure
    $stdout = original_stdout
    Pakyow.configure_logger
  end
  fake.string
end
