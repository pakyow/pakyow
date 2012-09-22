module Pakyow
  module Presenter
    class Attributes
      @@types = {
        :boolean  => [:selected, :checked, :disabled, :readonly, :multiple],
        :multiple => [:class]
      }

      def initialize(view)
        @view = view
      end

      def method_missing(method, *args)
        attribute = method.to_s

        if method.to_s.include?('=')
          attribute = attribute.gsub('=', '')
          value = args[0]

          self.set_attribute(attribute, value)
        else
          self.get_attribute(attribute)
        end
      end

      def class(*args)
        method_missing(:class, *args)
      end
      
      def id(*args)
        method_missing(:id, *args)
      end

      protected

      def set_attribute(attribute, value)
        type = self.type_of_attribute(attribute)

        value = value.call(self.deconstruct_attribute_value_of_type(@view.doc[attribute], type)) if value.is_a? Proc
        value = construct_attribute_value_of_type(value, type, attribute)
        
        if value.nil?
          @view.doc.remove_attribute(attribute)
        else
          @view.doc[attribute] = value
        end
      end

      def get_attribute(attribute)
        self.deconstruct_attribute_value_of_type(@view.doc[attribute], self.type_of_attribute(attribute))
      end

      def type_of_attribute(attribute)
        attribute = attribute.to_sym

        return :boolean  if @@types[:boolean].include?(attribute)
        return :multiple if @@types[:multiple].include?(attribute)
        return :single
      end

      def deconstruct_attribute_value_of_type(value, type)
        return value             if type == :single
        return value.split(' ')  if type == :multiple
        return !value.nil?       if type == :boolean
      end

      def construct_attribute_value_of_type(value, type, attribute)
        return value if type == :single
        return value.join(' ') if type == :multiple

        # pp value
        return value ? attribute : nil if type == :boolean
      end
    end

    class AttributesCollection
      include Enumerable

      def initialize
        @attributes = []
      end

      def <<(attributes)
        @attributes << attributes
      end

      def method_missing(method, *args)
        @attributes.each{|a| a.send(method, *args)}
      end
    end
  end
end
