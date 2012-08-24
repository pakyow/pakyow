module Pakyow
  class Cache
    def initialize
      @store = {}
    end

    def put(key, v)
      @store[key] = v
    end

    def get(key, &block)
      v = @store[key]
      if v == nil && block_given?
        v = block.call(key)
        @store[key] = v
      end
      v
    end

    def invalidate(key)
      put(key, nil)
    end

  end
end
