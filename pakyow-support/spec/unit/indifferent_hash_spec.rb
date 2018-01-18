require "pakyow/support/hash"
require "pakyow/support/indifferentize"

module Pakyow::Support
  RSpec.describe IndifferentHash do
    let :simple_hash do
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
    end

    let :subset do
      { two: :symbol, "three" => "Fantastic" }
    end

    let :other_set do
      { "three" => "Great" }
    end

    let :indifferent_subset do
      IndifferentHash.new(subset)
    end

    let :indifferent do
      IndifferentHash.new(simple_hash)
    end

    let :deep do
      IndifferentHash.deep(simple_hash)
    end

    let :simple_object do
      Object.new
    end

    context "when initializing with new" do
      it "converts string keys to symbols" do
        expect(indifferent.keys).to include(:two)
        expect(indifferent.keys).not_to include("two")
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

      # methods that do not take a key or hash argument
      %i(any? assoc compare_by_identity compare_by_identity default= default_proc default_proc= each each_key each_pair each_value empty? flatten hash include? index inspect key keys length rassoc rehash size shift to_a to_proc to_s value? values).each do |method|
        it "passes calls to #{method} to the internal hash" do
          internal = indifferent.internal_hash
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

          expect(internal).to receive(method).with(:key, any_args)
          indifferent.public_send(method, 'key', *args)

          expect(internal).to receive(method).with(:key, any_args)
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

          expect(internal).to receive(method).with(*symbol_args)
          indifferent.public_send(method, *string_args)

          expect(internal).to receive(method).with(*symbol_args)
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
        methods = [:merge!, :update, :replace, :clear, :keep_if, :delete_if, :compact!, :reject!, :select!, :deep_merge!]

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
        internal = indifferent.internal_hash
        expect(indifferent.to_hash.object_id).to eq(internal.object_id)
        expect(indifferent.to_h.object_id).to eq(internal.object_id)
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
    end
  end
end
