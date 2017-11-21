# frozen_string_literal: true

module Pakyow
  class Aargv
    def self.normalize(args, opts)
      Hash[opts.map { |opt_name, opt_opts|
        type, default = opt_opts

        [opt_name, value_of_type(args, type) || default]
      }.reject { |pair| pair[1].nil? }]
    end

    def self.value_of_type(values, type)
      if match = values.find { |value| value.is_a?(type) }
        values.delete(match)
      else
        nil
      end
    end
  end
end
