require "pakyow/support/hash"
require "pakyow/support/indifferentize"

module Pakyow::Support
  RSpec.describe IndifferentHash do
    let :simple_hash {
      {
        one: :symbol,
        "one" => "String",
        two: :symbol,
        "three" => "Fantastic",
        1 => "one", 
        Class => "Class",
        simple_object => "object",
        nested: {
          key: "value",
          "key" => "value",
          "nested" => {
            "a" => :a, b: "b", 3 => 3, Array => [{a: "b"}, {"b" => :c}]
          }
        }
      }
    }

    let :subset {
      { two: :symbol, "three" => "Fantastic" }
    }
    let :other_set {
      { "three" => "Great" }
    }

    let :indifferent_subset { IndifferentHash.new(subset) }
    let :indifferent { IndifferentHash.new(simple_hash) }
    let :deep { IndifferentHash.deep(simple_hash) }

    let :simple_object { Object.new }

    context "when initializing with new" do
      it "converts symbol keys to strings" do
        expect(indifferent.keys).to include("two")
        expect(indifferent.keys).not_to include(:two)
      end

      it "does not resolve conflicts" do
        expect(indifferent.keys.grep(/one/).length).to eql(1)
      end

      it "works with other objects as keys" do
        expect(indifferent.keys).to include(1)
        expect(indifferent.keys).to include(Class)
        expect(indifferent.keys).to include(simple_object)
      end

      it "can be accessed by both symbols and string keys" do
        expect(indifferent[:three]).to eql("Fantastic")
        expect(indifferent["three"]).to eql("Fantastic")
      end

      it "does not deep indifferentize" do
        expect(indifferent[:nested].keys).to eql([:key, "key", "nested"])
      end
    end

    context "when initializing with deep" do
      it "indifferntizes nested hashes" do
        expect(deep[:nested][:nested][:b]).to eql("b")
        expect(deep["nested"]["nested"]["b"]).to eql("b")
        expect(deep[:nested]["nested"][:b]).to eql("b")
      end

      it "indiffentizes nested arrays of hashes" do
        deep[:nested][:nested][Array].all? do |nested_hash|
          expect(nested_hash).to be_kind_of(IndifferentHash)
        end
      end
    end

    context "respecting the Hash api" do
      it "should have the same public api as Hash" do
        Hash.public_instance_methods.each do |method|
          expect(indifferent).to respond_to(method)
        end
      end

      it "should pass methods that do not take a key or hash argument to the internal hash" do
        internal = indifferent.internal_hash
        methods = %i(any? assoc compare_by_identity compare_by_identity default= default_proc default_proc= each each_key each_pair each_value empty? eql? flatten hash include? index inspect key keys length rassoc rehash size shift to_a to_proc to_s value? values)

        methods.each do |method|
          arity = Hash.public_instance_method(method).arity
          arity = 0 if arity < 0
          args = Array.new(arity, anything)

          matcher_args = if arity.zero?
                           no_args
                         else
                           args.dup
                         end

          expect(internal).to receive(method).with(*matcher_args).and_return(:whatever)

          expect(indifferent.public_send(method, *args)).to eq(:whatever)
        end
      end

      it "should use frozen string keys for methods that take single key args" do
        internal = indifferent.internal_hash
        methods = [:[], :[]=, :default, :delete, :fetch, :has_key?, :key?, :include?, :member?, :store]

        methods.each do |method|
          arity = Hash.public_instance_method(method).arity
          arity = 1 if arity < 0
          args = Array.new(arity - 1, anything)

          expect(internal).to receive(method).with('key', any_args)
          indifferent.public_send(method, 'key', *args)

          expect(internal).to receive(method).with('key', any_args)
          indifferent.public_send(method, :key, *args)
        end
      end

      it "should use frozen string keys for methods that take multiple key args" do
        internal = indifferent.internal_hash
        methods = [:fetch_values, :values_at, :dig]

        methods.each do |method|
          arity = Hash.public_instance_method(method).arity
          arity = 1 if arity < 0

          string_args = Array.new(arity, 'key').map.with_index do |key, i|
            [key, i].join('_')
          end
          symbol_args = string_args.map(&:to_sym)

          expect(internal).to receive(method).with(*string_args)
          indifferent.public_send(method, *string_args)

          expect(internal).to receive(method).with(*string_args)
          indifferent.public_send(method, *symbol_args)
        end
      end

      it "should return a new indifferent hash for methods that would return a new hash" do
        internal = indifferent.internal_hash
        methods = [:merge, :invert, :compact, :reject, :select, :transform_values, :deep_merge]

        methods.each do |method|
          arity = Hash.public_instance_method(method).arity
          arity = 1 if arity < 0
          args = Array.new(arity, anything)

          expect(internal).to receive(method).and_return({})

          expect(indifferent.public_send(method, *args)).to be_kind_of(
            IndifferentHash
          )
        end
      end

      it "should return a the same indifferent hash for methods that would return a hash modified in place" do
        internal = indifferent.internal_hash
        methods = [:merge!, :update, :replace, :clear, :keep_if, :delete_if, :compact!, :reject!, :select!, :transform_values, :deep_merge!]

        methods.each do |method|
          arity = Hash.public_instance_method(method).arity
          arity = 1 if arity < 0
          args = Array.new(arity, anything)

          expect(internal).to receive(method).and_return({})

          return_value = indifferent.public_send(method, *args)
          expect(return_value).to be_kind_of(IndifferentHash)
          expect(return_value.object_id).to eq(indifferent.object_id)
        end
      end
      
      it "should return the same indiffernt hash for to_hash/to_h" do
        expect(indifferent.to_hash.object_id).to eq(indifferent.object_id)
        expect(indifferent.to_h.object_id).to eq(indifferent.object_id)
      end

      it "should be equal to a hash" do
        expect(indifferent_subset).to eq(subset)
        expect(indifferent_subset).to eq(indifferent_subset)
      end

      it "should be greater than subset" do
        expect(indifferent).to be > subset
        expect(indifferent).to be > indifferent_subset
      end

      it "should not be less than subset" do
        expect(indifferent).not_to be < subset
        expect(indifferent).not_to be < indifferent_subset
      end

      it "should not be equal to subset" do
        expect(indifferent).not_to eq subset
        expect(indifferent).not_to eq indifferent_subset
      end

      it "should be greater than or equal to subset when greater" do
        expect(indifferent).to be >= subset
        expect(indifferent).to be >= indifferent_subset
      end

      it "should be greater than or equal to subset when equal" do
        expect(indifferent_subset).to be >= subset
        expect(indifferent_subset).to be >= indifferent_subset
      end

      it "should be less than or equal to subset when less" do
        expect(indifferent_subset).to be <= simple_hash
        expect(indifferent_subset).to be <= indifferent
      end

      it "should be less than or equal to subset when equal" do
        expect(indifferent_subset).to be <= subset
        expect(indifferent_subset).to be <= indifferent_subset
      end

      it "should shift like a hash, but with string keys" do
        simple_hash = {  }
      end

      it "should access the hash with [] for string, symbol or other keys" do
        expect(indifferent[:three]).to eq('Fantastic')
        expect(indifferent['three']).to eq('Fantastic')
        expect(indifferent[1]).to eq('one')
        expect(indifferent[Class]).to eq('Class')
        expect(indifferent[simple_object]).to eq('object')
      end

      it "should set the hash value with []= for string, symbol or other keys" do
        hash = indifferent.dup
        hash['two'] = 'Changed two'
        hash[:three] = 'Changed three'
        hash[1] = 'Changed one'
        hash[Class] = 'Changed Class'
        hash[simple_object] = 'Changed object'
        expect(hash[:two]).to eq('Changed two')
        expect(hash['two']).to eq('Changed two')
        expect(hash[:three]).to eq('Changed three')
        expect(hash['three']).to eq('Changed three')
        expect(hash[1]).to eq('Changed one')
        expect(hash[Class]).to eq('Changed Class')
        expect(hash[simple_object]).to eq('Changed object')
      end

=begin
      it "should clear the hash, returning self" do
        expect(indifferent.keys.length).to be > 0
        expect(indifferent.clear.object_id).to eq indifferent.object_id
        expect(indifferent.keys.length).to eq 0
      end

      it "should compact the hash, returning new indifferent hash" do
        simple_hash = { a: nil, b: 'Something' }
        indifferent = IndifferentHash.new(simple_hash)
        expect(indifferent.keys.length).to eq 2
        return_value = indifferent.compact
        expect(return_value).to be_kind_of IndifferentHash
        expect(indifferent.keys.length).to eq 2
        expect(return_value.keys.length).to eq 1
      end

      it "returns keys" do
        expect(indifferent.keys).to be_kind_of(Array)
      end

      it "should dig with indifferent access for deeply indifferntized hash" do
        expect(deep.dig(:nested, :nested, :a)).to eq :a
        expect(deep.dig('nested', 'nested', 'a')).to eq :a
      end
=end
    end
  end
end
