require 'rubygems'
require 'minitest'
require 'minitest/unit'
require 'minitest/spec'
require 'minitest/autorun'
require 'pry'
require 'pp'

require File.expand_path('../../../../pakyow-support/lib/pakyow-support', __FILE__)
require File.expand_path('../../../../pakyow-core/lib/pakyow-core', __FILE__)
require File.expand_path('../../../lib/pakyow-presenter', __FILE__)
require File.expand_path('../../../../pakyow-core/test/support/helper', __FILE__)

require_relative 'test_application'

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

def str_to_doc(str)
  if str.match(/<html.*>/)
    Nokogiri::HTML::Document.parse(str)
  else
    Nokogiri::HTML.fragment(str)
  end
end

