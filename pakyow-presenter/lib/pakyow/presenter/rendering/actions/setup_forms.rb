# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Presenter
    module Actions
      module SetupForms
        extend Support::Extension

        apply_extension do
          build do |app, view|
            view.forms.each do |form|
              form.object.set_label(:metadata, {})
            end
          end

          attach do |presenter|
            # TODO: forms need a whole lot of work to fit into the new pattern
            #
            #   * nothing in the form presenter relies on presenter, so move to view
            #
            #     - setting the endpoint does, but perhaps this can be refactored
            #
            #   * separate the concerns of building from that of attaching
            #
            #     during build:
            #
            #     - add metadata label (empty hash)
            #     - embed authenticity input
            #     - embed metadata input
            #     - embed method override input
            #
            #     during render:
            #
            #     - setup unless it's already been setup
            #       - set form id in metadata
            #       - set authenticity input value
            #       - set metadata input value
            #       - set method override input value
            #         - attach a transform that removes if value not set
            #
          end
        end
      end

      # @api private
      # class SetupForms
      #   def call(presenter)
      #     forms(presenter).each do |form|
      #       if form.view.object.labeled?(:metadata)
      #         unless form.view.labeled?(:__form_setup)
      #           if object = object_for_form(form, presenter)
      #             setup_form_for_exposed_object(form, object)
      #           elsif form.view.labeled?(:binding)
      #             case presenter.presentables[:__endpoint_name]
      #             when :new
      #               form.create
      #             when :edit
      #               form.update(presenter.presentables[:__params])
      #             else
      #               form.create
      #             end
      #           end
      #         end

      #         setup_form_id(form)

      #         unless form.view.labeled?(:__form_embed)
      #           setup_metadata(form, presenter)

      #           if presenter.presentables[:__embed_authenticity_token]
      #             setup_authenticity_token(form, presenter)
      #           end

      #           form.view.object.set_label(:__form_embed, true)
      #         end
      #       end
      #     end
      #   end

      #   private

      #   def forms(presenter)
      #     [].tap do |forms|
      #       if presenter.view.object.is_a?(StringDoc::Node) && presenter.view.form?
      #         forms << presenter.presenter_for(
      #           presenter.view, type: FormPresenter
      #         )
      #       end

      #       forms.concat(presenter.forms)
      #     end
      #   end

      #   def setup_form_for_exposed_object(form, object)
      #     if form.view.label(:endpoint)
      #       form.setup(object)
      #     else
      #       if object.key?(:id)
      #         form.update(object)
      #       else
      #         form.create(object)
      #       end
      #     end
      #   end

      #   def object_for_form(form, presenter)
      #     if form_binding_name = form.view.label(:binding)
      #       presenter.presentables[[form_binding_name].concat(form.view.label(:channel)).join(":").to_sym]
      #     end
      #   end

      #   def setup_metadata(form, presenter)
      #     form.embed_metadata(
      #       presenter.__verifier.sign(
      #         form.view.label(:metadata).to_json
      #       )
      #     )
      #   end

      #   def setup_authenticity_token(form, presenter)
      #     form.embed_authenticity_token(
      #       presenter.__verifier.sign(form.id),
      #       param: presenter.__csrf_param
      #     )
      #   end

      #   def setup_form_id(form)
      #     form.view.label(:metadata)[:id] ||= SecureRandom.hex(24)

      #     unless form.view.labeled?(FormPresenter::ID_LABEL)
      #       form.view.object.set_label(FormPresenter::ID_LABEL, form.view.label(:metadata)[:id])
      #     end
      #   end
      # end
    end
  end
end
