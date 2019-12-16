# frozen_string_literal: true

require "pakyow/support/extension"
require "pakyow/support/makeable"

module Pakyow
  module Helper
    extend Support::Extension

    # This is a bit nuanced, but this will cause isolated the helper module to be makeable.
    #
    extend_dependency Support::Makeable
  end
end
