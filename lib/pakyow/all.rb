# frozen_string_literal: true

%w(
  support
  core
  data
  presenter
  realtime
  ui
).each do |lib|
  require "pakyow/#{lib}"
end
