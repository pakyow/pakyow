require 'rspec'
require 'pry'
require 'pp'
require "pakyow"
require 'pakyow-support'

if ENV['COVERAGE']
  require 'simplecov'
  require 'simplecov-console'
  SimpleCov.formatter = SimpleCov::Formatter::Console
  SimpleCov.start
end
