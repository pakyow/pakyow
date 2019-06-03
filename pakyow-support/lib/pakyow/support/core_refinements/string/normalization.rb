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
          end
        end
      end
    end
  end
end
