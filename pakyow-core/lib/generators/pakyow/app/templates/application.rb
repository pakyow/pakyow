require 'rubygems'
require 'pakyow'

module PakyowApplication
  class Application < Pakyow::Application
    core do
      default {
        puts 'Pakyow says hello!'
      }
    end
  end
end
