# frozen_string_literal: true

class User < Sequel::Model
end

# Register the model object with pakyow as a data source. Makes it available in the model as `model.user`.
#
# Methods called through `model.user` are assumed to be queries, which fetch data but do not cause changes.
#
# Methods that cause changes to occur must be declared as commands.
#
Pakyow::App.source :user do
  object User

  # calls to these commands are passed through to the model object
  commands :create, :update, :destroy

  # queries / commands can also be defined here rather than on the model
end

# eventually we can have adapters... like:
#
# Pakyow::App.source :user, :sequel
#
# it would auto-define the model object, commands, etc
