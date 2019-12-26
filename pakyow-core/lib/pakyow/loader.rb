# frozen_string_literal: true

module Pakyow
  # Loads files that define an app aspect and names the objects appropriately.
  #
  class Loader
    def initialize(path)
      @code = File.read(path)
    end

    def call(target)
      case target
      when Class, Module
        target.class_eval(@code)
      else
        target.instance_eval(@code)
      end
    end
  end
end
