require 'rubygems'
require 'pakyow'

module PakyowApplication
  class Application < Pakyow::Application
    config.app.default_environment = :development
  
    configure(:development) do
    end
    
    routes do
      default :ApplicationController, :index
    end
    
    middleware do
    end
  end
end
