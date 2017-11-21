# frozen_string_literal: true

require "pakyow/presenter/attributes/string"

module Pakyow
  module Presenter
    module Attributes
      # Boolean is an odd attribute, since we ultimately want it to behave in this way:
      #
      #   view.attrs[:checked] = true
      #   => <input checked="checked" ...>
      #
      #   view.attrs[:checked] = false
      #   => <input ...>
      #
      # To support this, +ViewAttributes+ manages setting / removing the value on the
      # underlying object; all we do is behave like a String.
      #
      # @api private
      class Boolean < String
      end
    end
  end
end
