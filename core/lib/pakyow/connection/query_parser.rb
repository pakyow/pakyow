# frozen_string_literal: true

require "cgi"

require_relative "../error"

module Pakyow
  class Connection
    # Parses one or more query strings, building up a params hash. Supports nested query strings,
    # and enforces limits for key space size and total nested parameter depth.
    #
    # Aspects of this were inspired by Rack's query parser, including key space and depth limits. We
    # decided it was worth writing our own for several reasons:
    #
    #   1) Avoid Rack as a dependency for the majority use-case.
    #
    #   2) Improve the interface so you don't have to know ahead of time if you're dealing with a
    #      nested query string or not, and to allow for params to be built up from many strings.
    #
    #   3) Improve performance (up to 90% faster for a simple query string, 10% for nested).
    #
    # @api private
    class QueryParser
      class InvalidParameter < Error; end
      class KeySpaceLimitExceeded < Error; end
      class DepthLimitExceeded < Error; end

      DEFAULT_DELIMETER = /[&;,]/
      DEFAULT_KEY_SPACE_LIMIT = 102_400
      DEFAULT_DEPTH_LIMIT = 100

      attr_reader :params, :key_space_limit, :depth_limit

      def initialize(key_space_limit: DEFAULT_KEY_SPACE_LIMIT, depth_limit: DEFAULT_DEPTH_LIMIT, params: {})
        @params = params
        @key_space_limit = key_space_limit
        @key_space_size = 0
        @depth_limit = depth_limit
      end

      def parse(input, delimiter = DEFAULT_DELIMETER)
        input.to_s.split(delimiter).each do |part|
          key, value = part.split("=", 2)
          key = unescape(key).strip if key
          value = unescape(value).strip if value
          add_value_for_key(value, key)
        end

        @params
      end

      def add(key, value, params = @params)
        unless params.key?(key)
          @key_space_size += key.size
        end

        if @key_space_size > @key_space_limit
          raise KeySpaceLimitExceeded, "key space limit (#{@key_space_limit}) exceeded by `#{key}'"
        else
          params[key] = value
        end
      end

      def add_value_for_key(value, key, params = @params, depth = 0)
        if depth > @depth_limit
          raise DepthLimitExceeded, "depth limit (#{@depth_limit}) exceeded by `#{key}'"
        end

        if key&.include?("[") && key&.include?("]")
          opened = false
          read, nested = +"", nil

          key.length.times do |i|
            char = key[i]

            if char == "["
              opened = true
            elsif char == "]" && opened
              opened = false

              case params
              when Array
                nested_value = if nested
                  if (current_nested_value = params.last)
                    unless current_nested_value.is_a?(@params.class)
                      raise InvalidParameter, "expected `#{read}' to be #{@params.class} (got #{current_nested_value.class})"
                    end

                    if current_nested_value.key?(nested)
                      (params << @params.class.new).last
                    else
                      current_nested_value
                    end
                  else
                    (params << @params.class.new).last
                  end
                elsif (current_nested_value = params[read])
                  unless current_nested_value.is_a?(Array)
                    raise InvalidParameter, "expected `#{read}' to be Array (got #{current_nested_value.class})"
                  end

                  current_nested_value
                else
                  (params << []).last
                end
              when @params.class
                nested_value = if nested
                  if (current_nested_value = params[read])
                    unless current_nested_value.is_a?(@params.class)
                      raise InvalidParameter, "expected `#{read}' to be #{@params.class} (got #{current_nested_value.class})"
                    end

                    current_nested_value
                  else
                    @params.class.new
                  end
                elsif (current_nested_value = params[read])
                  unless current_nested_value.is_a?(Array)
                    raise InvalidParameter, "expected `#{read}' to be Array (got #{current_nested_value.class})"
                  end

                  current_nested_value
                else
                  []
                end

                add(read, nested_value, params)
              end

              j = i + 1
              if (next_char = key[j]) && next_char != "["
                raise InvalidParameter, "expected `#{nested}' to be #{params.class} (got String)"
              else
                add_value_for_key(value, (nested || +"") << key[j..-1], nested_value, depth + 1)
                break
              end
            elsif opened
              (nested ||= +"") << char
            else
              read << char
            end
          end
        else
          case params
          when Array
            params << value
          when @params.class
            if depth == 0 && (current_value = params[key]) && !(current_value.is_a?(Array) || current_value.is_a?(@params.class))
              if current_value.is_a?(Array)
                current_value << value
              else
                current_value = [current_value, value]
                add(key, current_value, params)
              end
            elsif key && !key.empty?
              add(key, value, params)
            end
          end
        end
      end

      private

      def unescape(string)
        CGI.unescape(string)
      end
    end
  end
end
