# frozen_string_literal: true

%w(
  support
  core
  data
  presenter
  assets
  realtime
  ui
).each do |lib|
  require "pakyow/#{lib}"
end
