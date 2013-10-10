require 'haml'

Pakyow::App.processor :haml do |content|
  Haml::Engine.new(content).render
end
