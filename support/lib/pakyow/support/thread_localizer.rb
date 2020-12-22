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

        unless frozen?
          keys = thread_localized_keys
          ObjectSpace.define_finalizer(self, method(:cleanup_thread_localized_keys)) if keys.empty?
          keys << key
        end
      end

      # Returns the localized value for `key`, or `fallback`.
      #
      def thread_localized(key, fallback = nil)
        key = thread_local_key(key)

        ThreadLocalizer.thread_localized_store.fetch(key, fallback)
      end

      # Deletes the localized value for `key`.
      #
      def delete_thread_localized(key)
        ThreadLocalizer.thread_localized_store.delete(thread_local_key(key))
      end

      private def thread_local_key(name)
        :"__pw_#{object_id}_#{name}"
      end

      private def thread_localized_keys
        @_thread_localized_keys ||= []
      end

      private def cleanup_thread_localized_keys
        @_thread_localized_keys.each do |key|
          ThreadLocalizer.thread_localized_store.delete(key)
        end

        @_thread_localized_keys.clear
      end

      def self.thread_localized_store
        Thread.current[:__pw] ||= Store.new
      end
    end
  end
end
