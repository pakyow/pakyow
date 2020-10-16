# frozen_string_literal: true

require_relative "../../errors"

module Pakyow
  module Runnable
    class Formation
      # Parses a formation string into a `Pakyow::Formation` instance.
      #
      class Parser
        def initialize(string)
          @string = string.to_s
          @container = nil
          @formation = nil
        end

        # Returns the formation, parsing the string if necessary.
        #
        def formation
          parse! unless parsed?

          @formation
        end

        # @api private
        private def parsed?
          !@formation.nil?
        end

        # @api private
        private def parse!
          entries = @string.split(",").map { |entry|
            entry.split(".", 2).map(&:strip)
          }

          containers = entries.map { |entry|
            entry.shift.to_sym
          }

          entries.flatten!

          if containers.uniq.count > 1
            raise FormationError.new_with_message(:multiple, formation: @string, containers: containers.uniq)
          end

          @formation = Formation.build(containers.first) { |formation|
            nested_formations = {}

            entries.each do |entry|
              if entry.include?(".")
                nested = Formation.parse(entry)

                if nested_formations.include?(nested.container)
                  nested_formations[nested.container].merge!(nested)
                else
                  nested_formations[nested.container] = nested
                end
              else
                formation.run(*entry.split("=").map(&:strip))
              end
            end

            nested_formations.each_value do |nested_formation|
              formation << nested_formation

              unless formation.service?(nested_formation.container)
                formation.run(:all)
              end
            end
          }
        end
      end
    end
  end
end
