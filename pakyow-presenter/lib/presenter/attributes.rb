module Pakyow
  module Presenter
    class Attributes
      def initialize(view)
        @view = view
      end

      def method_missing(method, *args)
        if method.to_s.include?('=')
          attribute = method.to_s.gsub('=', '')
          value = args[0]

          if value.is_a? Proc
            value = value.call(@view.doc[attribute])
          end

          if value.nil?
            @view.doc.remove_attribute(attribute)
          else
            @view.doc[attribute] = value
          end
        else
          return @view.doc[method.to_s]
        end
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
