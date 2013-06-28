module Pakyow
  module Presenter
    class Attribute
      @@types = {
        :hash => [:style],
        :bool => [:selected, :checked, :disabled, :readonly, :multiple],
        :mult => [:class]
      }

      def initialize(name, raw_value, control, doc)
        @type = type_of_attribute(name)
        @name = name
        @value = deconstruct_attribute_value_of_type(raw_value, @type)
        @control = control
        @doc = doc
      end

      def set(value)
        value = [value] if @type == :mult && !value.is_a?(Array) && !value.is_a?(Proc)
        @value = value
        update_value
      end

      # ensures that the value passed is contained in `value`
      def ensure(value)
        case @type
        when :mult
          @value << value unless @value.include?(value)
        when :bool
          @value = value
        else
          @value << value if @value.nil? || !@value.match(value)
        end

        update_value
      end

      # passes method call to `value`
      def method_missing(method, *args)
        ret = @value.send(method, *args)
        update_value

        return ret
      end

      # returns the full string value
      def to_s
        value = @value
        value = value.call(deconstruct_attribute_value_of_type(@doc[@name], @type)) if value.is_a? Proc
        value = construct_attribute_value_of_type(value, @type, @name)

        return value
      end

      def value
        @value
      end

      private

      def update_value
        updated_value = to_s

        if updated_value.nil?
          @control.remove_attribute(@name)
        else
          @control.update_value_for_attribute(@name, updated_value)
        end
      end

      def type_of_attribute(attribute)
        attribute = attribute.to_sym

        return :bool  if @@types[:bool].include?(attribute)
        return :mult if @@types[:mult].include?(attribute)
        return :hash     if @@types[:hash].include?(attribute)
        return :single
      end

      def deconstruct_attribute_value_of_type(value, type)
        return value ? value : ''             if type == :single
        return value ? value.split(' ') : []  if type == :mult
        return !value.nil?                    if type == :bool
        return value_to_hash(value)           if type == :hash
      end

      def construct_attribute_value_of_type(value, type, attribute)
        return value if type == :single
        return value.join(' ') if type == :mult
        return value ? attribute : nil if type == :bool
        return value.to_a.map {|a| a.join(':')}.join(';') if type == :hash
      end

      def value_to_hash(value)
        return {} if value.nil?

        value.split(';').inject({}) {|h, style|
          k,v = style.split(':')
          h[k.to_sym] = v
          h
        }
      end
    end

    class Attributes
      def initialize(doc)
        @doc = doc
        @attributes = {}
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

      def update_value_for_attribute(attribute, value)
        @doc[attribute] = value
      end

      def remove_attribute(attribute)
        @doc.remove_attribute(attribute)
      end

      protected

      def set_attribute(attribute, value)
        get_attribute(attribute).set(value)
      end

      def get_attribute(attribute)
        unless a = @attributes[attribute]
          a = Attribute.new(attribute, @doc[attribute], self, @doc)
        end

        return a
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
        ret = []
        @attributes.each{|a| ret << a.send(method, *args)}
        ret
      end

      def class(*args)
        method_missing(:class, *args)
      end
      
      def id(*args)
        method_missing(:id, *args)
      end
    end
  end
end
