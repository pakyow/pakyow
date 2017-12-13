# frozen_string_literal: true

%w(
  support
  core
  data
  presenter
).each do |lib|
  require "pakyow/#{lib}"
end
