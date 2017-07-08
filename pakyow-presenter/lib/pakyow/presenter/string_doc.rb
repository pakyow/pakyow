require "pakyow/support/silenceable"

module Pakyow
  module Presenter
    # @api private
    class StringDoc
      class << self
        def from_structure(structure)
          instance = allocate
          instance.instance_variable_set(:@structure, structure)
          return instance
        end

        def ensure(object)
          return object if object.is_a?(StringDoc)
          StringDoc.new(object)
        end

        def parse(doc)
          structure = []

          unless doc.is_a?(Oga::XML::Element) || !doc.respond_to?(:doctype) || doc.doctype.nil?
            structure << StringNode.new(["<!DOCTYPE html>", StringAttributes.new, []])
          end

          breadth_first(doc) do |node, queue|
            if node == doc
              queue.concat(node.children.to_a); next
            end

            # TODO: why do we do this? optimization?
            children = node.children.reject {|n| n.is_a?(Oga::XML::Text)}

            # this is an optimization we can make because we don't care about this node and
            # we know that nothing inside of it is significant, so we can just collapse it
            if !structure.empty? && children.empty? && !significant?(node)
              structure << StringNode.new([node.to_xml, StringAttributes.new, []]); next
            end

            if significant?(node)
              significant_type = significance(node)

              element = case significant_type
              when :container
                StringNode.new([node.to_xml, StringAttributes.new], type: :container, name: container_name(node))
              when :partial
                StringNode.new([node.to_xml, StringAttributes.new], type: :partial, name: partial_name(node))
              when :scope
                attributes = attributes_instance(node)
                scope = attributes.keys.first
                attributes[:"data-scope"] = scope
                attributes.delete(scope)

                StringNode.new(["<#{node.name} ", attributes], type: :scope, name: scope)
              when :prop
                attributes = attributes_instance(node)
                prop = attributes.keys.first
                attributes[:"data-prop"] = prop
                attributes.delete(prop)

                StringNode.new(["<#{node.name} ", attributes], type: :prop, name: prop)
              else
                StringNode.new(["<#{node.name} ", attributes_instance(node)], type: significant_type)
              end

              tag = if node.is_a?(Oga::XML::Element)
                node.name
              else
                nil
              end

              element.close(tag, parse(node))

              structure << element
            else # insignificant
              if node.is_a?(Oga::XML::Text) || node.is_a?(Oga::XML::Comment)
                structure << StringNode.new([node.to_xml, StringAttributes.new, []])
              else
                element = StringNode.new(["<#{node.name}#{attributes_string(node)}", StringAttributes.new])
                element.close(node.name, parse(node)) if node.is_a?(Oga::XML::Element)
                structure << element
              end
            end
          end

          structure
        end

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
            return true if __send__(:"#{name}?", node)
          end

          false
        end

        def significance(node)
          significant_types.each do |name, block|
            return name if __send__(:"#{name}?", node)
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

        def attributes_instance(node)
          StringAttributes.new(attributes_hash(node))
        end

        def attributes_hash(node)
          hash = attributes(node).each_with_object({}) do |attribute, structure|
            structure[attribute.name.to_sym] = attribute.value
          end
        end

        def attributes_string(node)
          attributes(node).each_with_object("") do |attribute, string|
            string << " #{attribute.name}=\"#{attribute.value}\""
          end
        end
      end

      include Support::Silenceable

      attr_reader :structure, :significant_nodes

      TITLE_REGEX = /<title>(.*?)<\/title>/m.freeze
      PARTIAL_REGEX = /@include\s*([a-zA-Z0-9\-_]*)/.freeze
      CONTAINER_REGEX = /@container\s*([a-zA-Z0-9\-_]*)/.freeze

      significant :scope
      significant :prop
      significant :container
      significant :partial
      significant :option
      significant :component

      def initialize(html)
        @structure = self.class.parse(Oga.parse_html(html))
      end

      def initialize_copy(original)
        super

        @structure = @structure.map { |node|
          node.dup
        }
      end

      def title
        title_search do |n, match|
          return match[1]
        end
      end

      def title=(title)
        title_search do |n, match|
          n.gsub!(TITLE_REGEX, "<title>#{title}</title>")
        end
      end

      def clear
        structure.clear
      end

      def append(doc)
        children.concat(StringDoc.ensure(doc).structure)
      end

      def prepend(doc)
        children.unshift(*StringDoc.ensure(doc).structure)
      end

      def after(doc)
        structure.concat(StringDoc.ensure(doc).structure)
      end

      def before(doc)
        structure.unshift(*StringDoc.ensure(doc).structure)
      end

      def replace(doc)
        @structure = StringDoc.ensure(doc).structure
      end

      def scope(name)
        scopes[name] || []
      end

      def prop(name)
        props[name] || []
      end

      def container(name)
        containers.find { |container| container[:name] == name }
      end

      # TODO: hook this up
      def component(name)
        # components.select { |c| c[:component] == name }
      end

      # TODO: hook this up
      def channel(name)
        # find_channel(scopes, name)
      end

      def containers
        @containers ||= structure.map(&:with_children).flatten.select { |element| element.type == :container }
      end

      def partials
        @partials ||= structure.map(&:with_children).flatten.select { |element|
          element.type == :partial
        }.each_with_object({}) do |partial, partials|
          (partials[partial.name] ||= []) << partial
        end
      end

      def scopes
        @scopes ||= structure.map(&:with_children).flatten.select { |element|
          element.type == :scope
        }.each_with_object({}) do |scope, scopes|
          (scopes[scope.name] ||= []) << scope
        end
      end

      def props
        @props ||= structure.map(&:with_children).flatten.select { |element|
          element.type == :prop
        }.each_with_object({}) do |prop, props|
          (props[prop.name] ||= []) << prop
        end
      end

      # TODO: hook this up
      def components
        {}
        # find_components(@node ? [@node] : @structure)
      end

      def to_html
        render
      end
      alias :to_s :to_html

      def ==(o)
        #TODO do this without rendering?
        # (at least in the case of comparing StringDoc to StringDoc)
        to_s == o.to_s
      end

      def mixin(partial_map)
        partials.each do |partial_name, partial_docs|
          next unless partial = partial_map[partial_name]

          partial_docs.each do |partial_doc|
            replacement = partial.doc.dup
            replacement.mixin(partial_map)

            partial_doc.replace(replacement)
          end
        end
      end

      private

      def render(structure = @structure)
        structure.flatten.reject(&:empty?).map(&:to_s).join
      end

      def title_search
        @structure.flatten.each do |n|
          next unless n.is_a?(String)
          if match = n.match(TITLE_REGEX)
            yield n, match
          end
        end
      end
    end
  end
end
