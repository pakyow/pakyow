require "pakyow/support/silenceable"

module Pakyow
  module Presenter
    class StringDocParser
      class << self
        def significant(name, &block)
          significant_types << name
        end

        def significant_types
          @significant_types ||= []
        end

        def breadth_first(doc)
          queue = [doc]
          until queue.empty?
            yield queue.shift, queue
          end
        end

        def significant?(node)
          significant_types.each do |name|
            return true if __send__("#{name}?", node)
          end

          false
        end

        def significance(node)
          significant_types.each do |name, block|
            return name if __send__("#{name}?", node)
          end

          nil
        end

        def scope?(node)
         if node.is_a?(Oga::XML::Element)
           if attribute = node.attributes.first
             if attribute.name && !attribute.value
               breadth_first(node) do |child, queue|
                 if child == node
                   queue.concat(child.children.to_a); next
                 end

                 if significant?(child)
                   return true
                 end
               end
             end
           end
         end

         false
       end

       def prop?(node)
          if node.is_a?(Oga::XML::Element)
            if attribute = node.attributes.first
              if attribute.name && !attribute.value
                breadth_first(node) do |child, queue|
                  if child == node
                    queue.concat(child.children.to_a); next
                  end

                  return false if significant?(child)
                end

                true
              end
            end
          end
        end

        def container?(node)
          node.is_a?(Oga::XML::Comment) && node.text.strip.match(CONTAINER_REGEX)
        end

        def partial?(node)
          node.is_a?(Oga::XML::Comment) && node.to_xml.strip.match(PARTIAL_REGEX)
        end

        def option?(node)
          node.is_a?(Oga::XML::Element) && node.name == 'option'
        end

        def component?(node)
          node.is_a?(Oga::XML::Element) && node.attribute('data-ui')
        end
      end

      include Support::Silenceable

      PARTIAL_REGEX = /@include\s*([a-zA-Z0-9\-_]*)/.freeze
      CONTAINER_REGEX = /@container\s*([a-zA-Z0-9\-_]*)/.freeze

      attr_reader :structure

      significant :scope
      significant :prop
      significant :container
      significant :partial
      significant :option
      significant :component

      def initialize(html)
        silence_warnings do
          @structure = parse(doc_from_string(html))
        end
      end

      protected

      # Parses HTML and returns a nested structure representing the document.
      #
      def parse(doc)
        structure = []

        unless doc.is_a?(Oga::XML::Element) || !doc.respond_to?(:doctype) || doc.doctype.nil?
          structure << ["<!DOCTYPE html>", {}, []]
        end

        self.class.breadth_first(doc) do |node, queue|
          if node == doc
            queue.concat(node.children.to_a); next
          end

          # TODO: why do we do this? optimization?
          children = node.children.reject {|n| n.is_a?(Oga::XML::Text)}

          # this is an optimization we can make because we don't care about this node and
          # we know that nothing inside of it is significant, so we can just collapse it
          if !structure.empty? && children.empty? && !self.class.significant?(node)
            structure << [node.to_xml, {}, []]; next
          end

          if self.class.significant?(node)
            case self.class.significance(node)
            when :container
              structure << [node.to_xml, { container: container_name(node) }, []]
            when :partial
              structure << [node.to_xml, { partial: partial_name(node) }, []]
            when :scope
              attributes = attributes_hash(node)
              scope = attributes.keys.first
              attributes[:"data-scope"] = scope
              attributes.delete(scope)

              structure << ["<#{node.name} ", attributes, close(node)]
            when :prop
              attributes = attributes_hash(node)
              prop = attributes.keys.first
              attributes[:"data-prop"] = prop
              attributes.delete(prop)

              structure << ["<#{node.name} ", attributes, close(node)]
            else
              structure << ["<#{node.name} ", attributes_hash(node), close(node)]
            end
          else # insignificant
            if node.is_a?(Oga::XML::Text) || node.is_a?(Oga::XML::Comment)
              structure << [node.to_xml, {}, []]
            else
              structure << ["<#{node.name}#{attributes_string(node)}", {}, close(node)]
            end
          end
        end

        structure
      end

      def doc_from_string(string)
        Oga.parse_html(string)
      end

      def container_name(node)
        (node.text.strip.match(CONTAINER_REGEX)[2] || :default).to_sym
      end

      def partial_name(node)
        node.text.strip.match(PARTIAL_REGEX)[1].to_sym
      end

      def attributes(node)
        if node.is_a?(Oga::XML::Element)
          node.attributes
        else
          []
        end
      end

      def attributes_hash(node)
        attributes(node).each_with_object({}) do |attribute, structure|
          structure[attribute.name.to_sym] = attribute.value
        end
      end

      def attributes_string(node)
        attributes(node).each_with_object("") do |attribute, string|
          string << " #{attribute.name}=\"#{attribute.value}\""
        end
      end

      def close(node)
        closing = [[">", {}, parse(node)]]
        closing << ["</#{node.name}>", {}, []] unless DocHelpers.self_closing_tag?(node.name)
        closing
      end
    end
  end
end
