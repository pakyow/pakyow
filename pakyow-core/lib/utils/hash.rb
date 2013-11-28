module Pakyow
  module Utils

    # Utility methods for hashes.
    class Hash
      # Creates an indifferent hash. This means that when indifferentized, this hash:
      #   { 'foo' => 'bar' }
      #
      # Can be accessed like this:
      #   { :foo => 'bar' }
      #
      def self.strhash(hash)
        indifferentize(hash)
      end

      # Converts keys to symbols.
      def self.symbolize_keys(hash)
        ::Hash[hash.map{|(k,v)| [k.to_sym,v]}]
      end

      # Converts keys/values to symbols.
      def self.symbolize(hash)
        ::Hash[hash.map{|(k,v)| [k.to_sym,v.to_sym]}]
      end

      protected

      # (see {strhash})
      def self.indifferentize(hash)
        hash.each_pair do |key, value|
          hash[key] = indifferentize(value) if value.is_a? ::Hash
        end

        indifferent_hash.merge(hash)
      end

      # (see {strhash})
      def self.indifferent_hash
        ::Hash.new { |hash,key| hash[key.to_s] if Symbol === key }
      end
    end

  end
end
