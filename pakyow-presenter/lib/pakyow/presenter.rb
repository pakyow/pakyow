# frozen_string_literal: true

require_relative "presenter/errors"
require_relative "presenter/framework"

require_relative "behavior/presenter/multiapp"
require_relative "behavior/presenter/relocate_frontend"

module Pakyow
  include Behavior::Presenter::Multiapp
  include Behavior::Presenter::RelocateFrontend
end
