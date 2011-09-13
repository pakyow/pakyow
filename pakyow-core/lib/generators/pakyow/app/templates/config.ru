env = ENV['RACK_ENV'] || 'production'

require File.expand_path('../config/application', __FILE__)
run PakyowApplication::Application.stage(env)
