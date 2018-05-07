# frozen_string_literal: true

require "pakyow/core/framework"

require "pakyow/forms/behavior/setup"
require "pakyow/forms/extensions/presenter/significant_nodes"
require "pakyow/forms/form_presenter"
require "pakyow/forms/form_view"

module Pakyow
  module Forms
    class Framework < Pakyow::Framework(:forms)
      def boot
        app.class_eval do
          const_get(:Renderer).class_eval do
            include Behavior::Setup
          end

          const_get(:Presenter).class_eval do
            # Returns the named form from the view being presented.
            #
            def form(name)
              if form_node = @view.object.find_significant_nodes(:form).find { |form| form.label(:binding) == name }
                presenter_for(FormView.from_object(form_node), type: FormPresenter)
              else
                nil
              end
            end

            # Returns all forms.
            #
            def forms
              @view.object.find_significant_nodes(:form).map { |form_node|
                presenter_for(FormView.from_object(form_node), type: FormPresenter)
              }
            end
          end
        end
      end
    end
  end
end
