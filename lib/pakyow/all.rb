# frozen_string_literal: true

%w(
  support
  core
  data
  presenter
  forms
  assets
  realtime
  ui
).each do |lib|
  require "pakyow/#{lib}"
end
