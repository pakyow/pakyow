# frozen_string_literal: true

require "redcarpet"

require "pakyow/error"
require "pakyow/support/safe_string"

module Pakyow
  class Error
    include Support::SafeStringHelpers

    def [](key)
      if respond_to?(key)
        public_send(key)
      else
        nil
      end
    end

    def include?(key)
      respond_to?(key)
    end

    def presentable_message
      safe(markdown.render(message))
    end

    def presentable_details
      safe(markdown.render(details))
    end

    def presentable_backtrace
      safe(backtrace.to_a.join("<br>"))
    end

    private

    def markdown
      @markdown ||= Redcarpet::Markdown.new(
        Redcarpet::Render::HTML.new({})
      )
    end
  end
end
