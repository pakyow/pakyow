# frozen_string_literal: true

require "pakyow/core"
require "pakyow/presenter"
require "pakyow/data"

Pakyow::App.define do
  include Pakyow::Presenter

  configure do
    config.name = "example"

    DB = Sequel.connect(adapter: 'sqlite')

    DB.create_table :users do
      primary_key :id
      String :name
    end
  end

  configure :development do
  end
end
