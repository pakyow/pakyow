# frozen_string_literal: true

require "pakyow/support/extension"

require "pakyow/command"

module Pakyow
  module Behavior
    module Commands
      extend Support::Extension

      apply_extension do
        definable :command, Command
      end
    end
  end
end
