# frozen_string_literal: true

GEMS = %i[
  support
  core
  data
  presenter
  assets
  mailer
  realtime
  ui
].freeze

Dir.glob("tasks/*.rake").each do |r| import r end
task default: %w(test:all)
