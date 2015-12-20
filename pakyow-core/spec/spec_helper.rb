require 'rspec'
require 'pry'
require 'pp'

if ENV['COVERAGE']
  require 'simplecov'
  require 'simplecov-console'
  SimpleCov.formatter = SimpleCov::Formatter::Console
  SimpleCov.start
end
