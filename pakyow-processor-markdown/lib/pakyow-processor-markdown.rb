require 'rdiscount'

Pakyow::App.processor :md, :mdown, :markdown do |content|
  RDiscount.new(content).to_html
end
