module Pakyow

  # Utility methods for hashes.
  class HashUtils
    # Creates an indifferent hash. This means that when indifferentized, this hash:
    #   { 'foo' => 'bar' }
    #
    # Can be accessed like this:
    #   { :foo => 'bar' }
    #
    def self.strhash(hash)
      indifferentize(hash)
    end
    
    protected
    
    # (see {strhash})
    def self.indifferentize(hash)
      hash.each_pair do |key, value|
        hash[key] = indifferentize(value) if value.is_a? Hash
      end
      
      indifferent_hash.merge(hash)
    end
    
    # (see {strhash})
    def self.indifferent_hash
      Hash.new { |hash,key| hash[key.to_s] if Symbol === key }
    end
  end
end
