# frozen_string_literal: true

require "pakyow/support/deprecatable"

module Pakyow
  # A process, runnable within a {ProcessManager}.
  #
  # @deprecated
  #
  class Process
    extend Support::Deprecatable
    deprecate

    attr_reader :name, :count

    def initialize(name:, count: 1, restartable: false, &block)
      @name, @count, @restartable, @block = name, count.to_i, restartable, block
    end

    # Returns `true' if this process is restartable.
    #
    def restartable?
      @restartable == true
    end

    # Calls the given block associated with this process.
    #
    def call
      @block.call
    end
  end
end

