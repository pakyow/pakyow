# frozen_string_literal: true

module Pakyow
  class Router
    def_delegators :controller, :data, :verify
  end
end
