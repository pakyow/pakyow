module Pakyow
  module Presenter
    class BindingParts
      attr_reader :parts

      def initialize
        @parts = {}
      end

      def define_part(name, value)
        @parts[name] = value
      end

      def content?
        @parts.include?(:content)
      end

      def content
        @parts[:content]
      end

      def non_content_parts
        @parts.reject { |name, _| name == :content }
      end

      def reject(*parts)
        parts = parts.map(&:to_sym)
        @parts.delete_if { |key, _| parts.include? key }
      end

      def accept(*parts)
        return if parts.empty?
        parts = parts.map(&:to_sym)
        @parts.keep_if { |key, _| parts.include? key }
      end
    end
  end
end
