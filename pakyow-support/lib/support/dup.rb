module Pakyow
  module Utils
    module Dup
      def self.deep(value)
        return value if value.is_a?(Symbol)
        if value.is_a?(Hash)
          result = value.clone
          value.each { |k, v| result[deep(k)] = deep(v) }
          result
        elsif value.is_a?(Array)
          result = value.clone
          result.clear
          value.each{ |v| result << deep(v) }
          result
        else
          value.clone
        end
      end
    end
  end
end
