# frozen_string_literal: true

GEMS = %i[
  assets
  core
  data
  form
  mailer
  presenter
  realtime
  routing
  support
  ui
].freeze

Dir.glob("tasks/*.rake").each do |r| import r end
task default: %w(test:all)
