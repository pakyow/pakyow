# frozen_string_literal: true

module Pakyow
  # Base class for generators.
  #
  class Generator < Thor::Group
    include Thor::Actions
  end
end
