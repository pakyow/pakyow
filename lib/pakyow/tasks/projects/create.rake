# frozen_string_literal: true

# TODO: if it isn't that hard, it would be cool to have contextual tasks... like
# projects:create only shows up when called outside of a current project, while
# all the other tasks behave in the exact opposite manner
#
# though the tasks wouldn't show up, pakyow would still be aware of them and say
# something like "not available in this context"

namespace :projects do
  desc "Create a new project"
  task :create, [:path] do |_, args|
    # TODO: create at path, using basename as name
  end
end

# require "pakyow/commands/helpers"

# module Pakyow
#   # @api private
#   module Commands
#     # @api private
#     class Generate
#       include Helpers

#       def initialize(generator, app: nil, args: [])
#         @generator, @app, @args = generator, app, args
#       end

#       def run
#         require "./config/environment"
#         Pakyow.setup

#         if app_instance = find_app(@app)
#           @args.unshift(app_instance)
#           require "pakyow/generators/#{@generator}/#{@generator}_generator"
#           generator = Pakyow::Generators.const_get(Support.inflector.camelize(@generator))
#           generator.start(@args)
#         end
#       rescue LoadError
#         Pakyow.logger.error "Could not find generator named `#{@generator}'"
#       end
#     end
#   end
# end
