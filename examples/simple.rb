require 'rubygems'
require 'pakyow-core'

class HelloApp < Pakyow::Application
  routes do
    get '/' do
      response.body << "Pakyow Says Hello"
    end
  end
end

HelloApp.run
