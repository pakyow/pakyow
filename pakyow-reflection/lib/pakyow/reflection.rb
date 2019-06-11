# frozen_string_literal: true

require "pakyow/routing"
require "pakyow/presenter"

# Load data after presenter, so that containers are created with reflected attributes.
#
require "pakyow/data"

require "pakyow/form"

require "pakyow/reflection/framework"
