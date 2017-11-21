# frozen_string_literal: true

require "pakyow/core"
require "pakyow/presenter"

Pakyow::App.define do
  include Pakyow::Presenter

  configure do
    config.app.name = "example"
  end

  configure :development do
  end
end
