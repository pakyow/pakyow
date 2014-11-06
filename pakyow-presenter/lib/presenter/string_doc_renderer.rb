module Pakyow
  module Presenter
    class StringDocRenderer
      def self.render(structure)
        structure.flatten.reject(&:empty?).map { |s|
          s.is_a?(Hash) ? attrify(s) : s
        }.join
      end

      IGNORED_ATTRS = %i[container partial]
      def self.attrify(attrs)
        attrs.delete_if { |a| a.nil? || IGNORED_ATTRS.include?(a) }.map { |attr|
          attr[0].to_s + '="' + attr[1].to_s + '"'
        }.join(' ')
      end
    end
  end
end
