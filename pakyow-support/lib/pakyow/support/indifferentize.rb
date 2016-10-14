module Pakyow
  module Support
    class IndifferentHash < Hash
      def [](key)
        super(key.to_s)
      end

      def []=(key, value)
        super(key.to_s, value)
      end
    end

    module Indifferentize
      refine Hash do
        def indifferentize
          Pakyow::Support::IndifferentHash[self]
        end
      end
    end
  end
end
