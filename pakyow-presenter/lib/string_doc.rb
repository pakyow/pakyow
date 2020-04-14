# frozen_string_literal: true

require "cgi"

require "oga"

require "pakyow/support/inflector"
require "pakyow/support/silenceable"

# String-based XML document optimized for fast manipulation and rendering.
#
# In Pakyow, we rarely care about every node in a document. Instead, only significant nodes and
# immediate children are available for manipulation. StringDoc provides "just enough" for our
# purposes. A StringDoc is represented as a multi- dimensional array of strings, making
# rendering essentially a +flatten.join+.
#
# Because less work is performed during render, StringDoc is consistently faster than rendering
# a document using Nokigiri or Oga. One obvious tradeoff is that parsing is much slower (we use
# Oga to parse the XML, then convert it into a StringDoc). This is an acceptable tradeoff
# because we only pay the parsing cost once (when the Pakyow application boots).
#
# All that to say, StringDoc is a tool that is very specialized to Pakyow's use-case. Use it
# only when a longer parse time is acceptable and you only care about a handful of identifiable
# nodes in a document.
#
# @api private
#
class StringDoc
  require_relative "string_doc/attributes"
  require_relative "string_doc/node"
  require_relative "string_doc/meta_node"

  class << self
    # Creates an empty doc.
    #
    def empty
      allocate.tap do |doc|
        doc.instance_variable_set(:@nodes, [])
        doc.instance_variable_set(:@collapsed, nil)
      end
    end

    # Registers a significant node with a name and an object to handle parsing.
    #
    def significant(name, object, descend: true)
      significant_types[name] = { object: object, descend: descend }
    end

    # Creates a +StringDoc+ from an array of +Node+ objects.
    #
    def from_nodes(nodes)
      allocate.tap do |instance|
        instance.instance_variable_set(:@nodes, nodes)
        instance.instance_variable_set(:@collapsed, nil)

        nodes.each do |node|
          node.parent = instance
        end
      end
    end

    # Yields nodes from an oga document, breadth-first.
    #
    def breadth_first(doc)
      queue = [doc]

      until queue.empty?
        element = queue.shift

        if element == doc
          queue.concat(element.children.to_a); next
        end

        yield element
      end
    end

    # Returns attributes for an oga element.
    #
    def attributes(element)
      if element.is_a?(Oga::XML::Element)
        element.attributes
      else
        []
      end
    end

    # Builds a string-based representation of attributes for an oga element.
    #
    def attributes_string(element)
      attributes(element).each_with_object(String.new) do |attribute, string|
        string << " #{attribute.name}=\"#{attribute.value}\""
      end
    end

    # Determines the significance of +element+.
    #
    def find_significance(element)
      significant_types.each_with_object([]) do |(key, info), significance|
        if info[:object].significant?(element)
          significance << key
        end
      end
    end

    # Returns true if the given Oga element contains a child node that is significant.
    #
    def contains_significant_child?(element)
      element.children.each do |child|
        return true if find_significance(child).any?
        return true if contains_significant_child?(child)
      end

      false
    end

    # @api private
    def significant_types
      @significant_types ||= {}
    end

    # @api private
    def nodes_from_doc_or_string(doc_node_or_string)
      case doc_node_or_string
      when StringDoc
        doc_node_or_string.nodes
      when Node, MetaNode
        [doc_node_or_string]
      else
        StringDoc.new(doc_node_or_string.to_s).nodes
      end
    end
  end

  include Pakyow::Support::Silenceable

  # Array of +Node+ objects.
  #
  attr_reader :nodes, :collapsed

  # Creates a +StringDoc+ from an html string.
  #
  def initialize(html)
    @nodes = parse(Oga.parse_html(html))
    @collapsed = nil
  end

  # @api private
  def initialize_copy(_)
    super

    @nodes = @nodes.map { |node|
      node.dup.tap do |duped_node|
        duped_node.parent = self
      end
    }
  end

    # @api private
  def soft_copy
    instance = self.class.allocate

    instance.instance_variable_set(:@nodes, @nodes.map { |node|
      duped_node = node.soft_copy
      duped_node.parent = instance
      duped_node
    })

    instance.instance_variable_set(:@collapsed, @collapsed)

    instance
  end

  def finalize_labels(keep: [])
    @nodes.each do |node|
      node.finalize_labels(keep: keep)
    end
  end

  include Enumerable

  def each(descend: false, &block)
    return enum_for(:each, descend: descend) unless block_given?

    @nodes.each do |node|
      case node
      when MetaNode
        node.each do |each_meta_node|
          yield each_meta_node
        end
      else
        yield node
      end

      if descend || node.label(:descend) != false
        if node.children.is_a?(StringDoc)
          node.children.each(descend: descend, &block)
        else
          yield node.children
        end
      end
    end
  end

  # Yields each node matching the significant type.
  #
  def each_significant_node(type, descend: false)
    return enum_for(:each_significant_node, type, descend: descend) unless block_given?

    each(descend: descend) do |node|
      case node
      when MetaNode
        if node.significant?(type)
          node.each do |each_meta_node|
            yield each_meta_node
          end
        end
      when Node
        if node.significant?(type)
          yield node
        end
      end
    end
  end

  # Yields each node matching the significant type, without descending into nodes that are of that type.
  #
  def each_significant_node_without_descending_into_type(type, descend: false, &block)
    return enum_for(:each_significant_node_without_descending_into_type, type, descend: descend) unless block_given?

    @nodes.each do |node|
      if node.is_a?(Node) || node.is_a?(MetaNode)
        if node.significant?(type)
          case node
          when MetaNode
            node.each do |each_meta_node|
              yield each_meta_node
            end
          when Node
            yield node
          end
        else
          if descend || node.label(:descend) != false
            if node.children.is_a?(StringDoc)
              node.children.each_significant_node_without_descending_into_type(type, descend: descend, &block)
            else
              yield node.children
            end
          end
        end
      end
    end
  end

  # Yields each node matching the significant type and name.
  #
  # @see find_significant_nodes
  #
  def each_significant_node_with_name(type, name, descend: false)
    return enum_for(:each_significant_node_with_name, type, name, descend: descend) unless block_given?

    each_significant_node(type, descend: descend) do |node|
      yield node if node.label(type) == name
    end
  end

  # Returns the first node matching the significant type.
  #
  def find_first_significant_node(type, descend: false)
    each(descend: descend).find { |node|
      node.significant?(type)
    }
  end

  # Returns nodes matching the significant type.
  #
  def find_significant_nodes(type, descend: false)
    [].tap do |nodes|
      each_significant_node(type, descend: descend) do |node|
        nodes << node
      end
    end
  end

  # Returns nodes matching the significant type and name.
  #
  # @see find_significant_nodes
  #
  def find_significant_nodes_with_name(type, name, descend: false)
    [].tap do |nodes|
      each_significant_node_with_name(type, name, descend: descend) do |node|
        nodes << node
      end
    end
  end

  # Clears all nodes.
  #
  def clear
    tap do
      @nodes.clear
    end
  end
  alias remove clear

  # Replaces the current document.
  #
  # Accepts a +StringDoc+ or XML +String+.
  #
  def replace(doc_or_string)
    tap do
      nodes = self.class.nodes_from_doc_or_string(doc_or_string)

      nodes.each do |node|
        node.parent = self
      end

      @nodes = nodes
    end
  end

  # Appends to this document.
  #
  # Accepts a +StringDoc+ or XML +String+.
  #
  def append(doc_or_string)
    tap do
      nodes = self.class.nodes_from_doc_or_string(doc_or_string)

      nodes.each do |node|
        node.parent = self
      end

      @nodes.concat(nodes)
    end
  end

  # Appends raw html to this document, without parsing.
  #
  def append_html(html)
    tap do
      node = Node.new(html.to_s)
      node.parent = self
      @nodes << node
    end
  end

  # Prepends to this document.
  #
  # Accepts a +StringDoc+ or XML +String+.
  #
  def prepend(doc_or_string)
    tap do
      nodes = self.class.nodes_from_doc_or_string(doc_or_string)

      nodes.each do |node|
        node.parent = self
      end

      @nodes.unshift(*nodes)
    end
  end

  # Inserts a node after another node contained in this document.
  #
  def insert_after(node_to_insert, after_node)
    tap do
      if after_node_index = @nodes.index(after_node)
        nodes = self.class.nodes_from_doc_or_string(node_to_insert)

        nodes.each do |node|
          node.parent = self
        end

        @nodes.insert(after_node_index + 1, *nodes)
      end
    end
  end

  # Inserts a node before another node contained in this document.
  #
  def insert_before(node_to_insert, before_node)
    tap do
      if before_node_index = @nodes.index(before_node)
        nodes = self.class.nodes_from_doc_or_string(node_to_insert)

        nodes.each do |node|
          node.parent = self
        end

        @nodes.insert(before_node_index, *nodes)
      end
    end
  end

  # Removes a node from the document.
  #
  def remove_node(node_to_delete)
    tap do
      @nodes.delete_if { |node|
        node.equal?(node_to_delete)
      }
    end
  end

  # Replaces a node from the document.
  #
  def replace_node(node_to_replace, replacement_node)
    tap do
      if replace_node_index = @nodes.index(node_to_replace)
        nodes_to_insert = self.class.nodes_from_doc_or_string(replacement_node)

        nodes_to_insert.each do |node|
          node.parent = self
        end

        @nodes.insert(replace_node_index + 1, *nodes_to_insert)
        @nodes.delete_at(replace_node_index)
      end
    end
  end

  def render(output = String.new, context: nil)
    if collapsed && empty?
      output << collapsed
    else
      nodes.each do |node|
        case node
        when MetaNode
          node.render(output, context: context)
        when Node
          node.render(output, context: context)
        else
          output << node.to_s
        end
      end

      output
    end
  end
  alias :to_html :render
  alias :to_xml :render

  # Returns the node as an xml string, without transforming.
  #
  def to_s
    if collapsed && empty?
      collapsed
    else
      @nodes.each_with_object(String.new) do |node, string|
        string << node.to_s
      end
    end
  end

  def ==(other)
    other.is_a?(StringDoc) && @nodes == other.nodes
  end

  def collapse(*significance)
    if significance?(*significance)
      @nodes.each do |node|
        node.children.collapse(*significance)
      end
    else
      @collapsed = render
      @nodes = []
    end

    @collapsed
  end

  def significance?(*significance)
    @nodes.any? { |node|
      node.significance?(*significance) || node.children.significance?(*significance)
    }
  end

  def remove_empty_nodes
    @nodes.each do |node|
      node.children.remove_empty_nodes
    end

    unless empty?
      @nodes.delete_if(&:empty?)
    end
  end

  def empty?
    @nodes.empty?
  end

  def transforms?
    @nodes.any?(&:transforms?)
  end

  private

  # Parses an Oga document into an array of +Node+ objects.
  #
  def parse(doc)
    nodes = []

    unless doc.is_a?(Oga::XML::Element) || !doc.respond_to?(:doctype) || doc.doctype.nil?
      nodes << Node.new("<!DOCTYPE html>")
    end

    self.class.breadth_first(doc) do |element|
      significance = self.class.find_significance(element)

      unless significance.any? || self.class.contains_significant_child?(element)
        # Nothing inside of the node is significant, so collapse it to a single node.
        nodes << Node.new(element.to_xml); next
      end

      node = if significance.any?
        build_significant_node(element, significance)
      elsif element.is_a?(Oga::XML::Text) || element.is_a?(Oga::XML::Comment)
        Node.new(element.to_xml)
      else
        Node.new("<#{element.name}#{self.class.attributes_string(element)}")
      end

      if element.is_a?(Oga::XML::Element)
        node.close(element.name, parse(element))
      end

      nodes << node
    end

    nodes
  end

  # Attributes that should be prefixed with +data-+
  #
  DATA_ATTRS = %i(ui binding endpoint endpoint-action version).freeze

  # Attributes that will be turned into +StringDoc+ labels
  #
  LABEL_ATTRS = %i(ui mode version include exclude endpoint endpoint-action prototype binding dataset).freeze

  LABEL_MAPPING = {}.freeze

  # Attributes that should be deleted from the view
  #
  DELETED_ATTRS = %i(include exclude prototype mode dataset).freeze

  ATTR_MAPPING = {
    binding: :b,
    endpoint: :e,
    "endpoint-action": :"e-a",
    version: :v
  }.freeze

  def attributes_hash(element)
    StringDoc.attributes(element).each_with_object({}) { |attribute, elements|
      elements[attribute.name.to_sym] = CGI.escape_html(attribute.value.to_s)
    }
  end

  def labels_hash(element)
    StringDoc.attributes(element).dup.each_with_object({}) { |attribute, labels|
      attribute_name = attribute.name.to_sym

      if LABEL_ATTRS.include?(attribute_name)
        labels[LABEL_MAPPING.fetch(attribute_name, attribute_name)] = attribute.value.to_s.to_sym
      end
    }
  end

  def build_significant_node(element, significance)
    node = if element.is_a?(Oga::XML::Element)
      attributes = attributes_hash(element).each_with_object({}) { |(key, value), remapped_attributes|
        unless DELETED_ATTRS.include?(key)
          remapped_key = ATTR_MAPPING.fetch(key, key)

          if DATA_ATTRS.include?(key)
            remapped_key = :"data-#{remapped_key}"
          end

          remapped_attributes[remapped_key] = value || ""
        end
      }

      labels = labels_hash(element)

      if labels.include?(:binding)
        post_process_binding!(element, attributes, labels)
      end

      significance_options = significance.map { |significant_type|
        self.class.significant_types[significant_type]
      }

      labels[:descend] = significance_options.all? { |options| options[:descend] == true }

      Node.new("<#{element.name}", Attributes.new(attributes), significance: significance, labels: labels, parent: self)
    else
      name = element.text.strip.match(/@[^\s]*\s*([a-zA-Z0-9\-_]*)/)[1]
      labels = significance.each_with_object({}) { |significant_type, labels_hash|
        # FIXME: remove this special case logic
        labels_hash[significant_type] = if name.empty? && significant_type == :container
          Pakyow::Presenter::Views::Page::DEFAULT_CONTAINER
        else
          name.to_sym
        end
      }

      Node.new(element.to_xml, significance: significance, parent: self, labels: labels)
    end

    significance.each do |significant_type|
      object = StringDoc.significant_types.dig(significant_type, :object)
      if object && object.respond_to?(:decorate)
        object.decorate(node)
      end
    end

    node
  end

  def post_process_binding!(element, attributes, labels)
    channel = semantic_channel_for_element(element)
    binding = labels[:binding].to_s

    if binding.start_with?("@")
      plug, binding = binding.split(".", 2)
      plug_name, plug_instance = plug.split("(", 2)

      if plug_instance
        plug_instance = plug_instance[0..-2]
      else
        plug_instance = :default
      end

      labels[:plug] = {
        name: plug_name[1..-1].to_sym,
        instance: plug_instance.to_sym,
      }

      labels[:plug][:key] = if labels[:plug][:instance] == :default
        "@#{labels[:plug][:name]}"
      else
        "@#{labels[:plug][:name]}.#{labels[:plug][:instance]}"
      end
    end

    binding_parts = binding.split(":").map(&:to_sym)
    binding_name, binding_prop = binding_parts[0].to_s.split(".", 2).map(&:to_sym)
    plural_binding_name = Pakyow::Support.inflector.pluralize(binding_name).to_sym
    singular_binding_name = Pakyow::Support.inflector.singularize(binding_name).to_sym

    labels[:binding] = binding_name
    labels[:plural_binding] = plural_binding_name
    labels[:singular_binding] = singular_binding_name

    if binding_prop
      labels[:binding_prop] = binding_prop
    end

    channel.concat(binding_parts[1..-1])
    labels[:channeled_binding] = [binding_name].concat(channel).join(":").to_sym
    labels[:plural_channeled_binding] = [plural_binding_name].concat(channel).join(":").to_sym
    labels[:singular_channeled_binding] = [singular_binding_name].concat(channel).join(":").to_sym
    attributes[:"data-b"] = [binding_parts[0]].concat(channel).join(":")
  end

  SEMANTIC_TAGS = %w(
    form
  ).freeze

  def semantic_channel_for_element(element, channel = [])
    if SEMANTIC_TAGS.include?(element.name)
      channel << element.name.to_sym
    end

    channel
  end
end
