# frozen_string_literal: true

require_relative "extension"

module Pakyow
  module Support
    # Manages thread local state on classes and instances.
    #
    module ThreadLocalizer
      require_relative "thread_localizer/store"

      extend Support::Extension

      # Localize `value` for `key` in the current thread.
      #
      def thread_localize(key, value)
        key = thread_local_key(key)

        ThreadLocalizer.thread_localized_store[key] = value

        ObjectSpace.define_finalizer(self, ThreadLocalizer.cleanup_thread_localized(key))
      end

      # Returns the localized value for `key`, or `fallback`.
      #
      def thread_localized(key, fallback = nil)
        key = thread_local_key(key)

        ThreadLocalizer.thread_localized_store.fetch(key, fallback)
      end

      private def thread_local_key(name)
        :"__pw_#{object_id}_#{name}"
      end

      def self.thread_localized_store
        Thread.current[:__pw] ||= Store.new
      end

      # @api private
      def self.cleanup_thread_localized(key)
        proc { ThreadLocalizer.thread_localized_store.delete(key) }
      end
    end
  end
end
