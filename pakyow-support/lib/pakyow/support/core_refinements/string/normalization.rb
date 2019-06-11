# frozen_string_literal: true

module Pakyow
  module Support
    module Refinements
      module String
        module Normalization
          refine ::String.singleton_class do
            # Normalizes a string into a predictable path.
            #
            #   String.normalize_path("foo//bar/")
            #   # => "/foo/bar"
            #
            def normalize_path(path)
              path = path.to_s

              unless path.start_with?("/")
                path = "/#{path}"
              end

              if path.include?("//")
                path = path.to_s.gsub("//", "/")
              end

              unless path == "/"
                path = path.chomp("/")
              end

              path
            end

            # Collapses a string into a version without tokens.
            #
            #   String.collapse_path("/foo/:bar/baz")
            #   # => "/foo/baz"
            def collapse_path(path)
              if path == "/"
                return path
              end

              path.to_s.split("/").keep_if { |part|
                part[0] != ":"
              }.join("/")
            end
          end
        end
      end
    end
  end
end
