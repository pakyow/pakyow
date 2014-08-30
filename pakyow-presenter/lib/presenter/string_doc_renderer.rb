module Pakyow
  module Presenter
    class StringDocRenderer
      def self.render(structure)
        flatten(structure).flatten.join
      end

      def self.flatten(structure)
        structure.map { |content|
          content.is_a?(Array) ? contentify(content) : content
        }
      end

      def self.contentify(content)
        content.map { |p|
          case p
          when Hash
            attrify(p)
          when Array
            flatten(p)
          else
            p
          end
        }
      end

      IGNORED_ATTRS = %i[container partial]
      def self.attrify(attrs)
        attrs.delete_if { |a| a.nil? || IGNORED_ATTRS.include?(a) }.map { |attr|
          attr[0].to_s + '="' + attr[1] + '"'
        }.join(' ')
      end
    end
  end
end
