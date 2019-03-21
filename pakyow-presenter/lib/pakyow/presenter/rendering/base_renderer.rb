# frozen_string_literal: true

require "pakyow/support/class_state"
require "pakyow/support/deep_dup"
require "pakyow/support/hookable"
require "pakyow/support/pipeline"

module Pakyow
  module Presenter
    class BaseRenderer
      extend Support::ClassState

      class << self
        def restore(connection, serialized)
          new(connection, **serialized)
        end
      end

      include Support::Hookable
      events :render

      include Support::Pipeline
      include Support::Pipeline::Object

      using Support::DeepDup

      attr_reader :connection, :presenter

      def initialize(connection, presenter)
        @connection, @presenter = connection, presenter
      end

      def perform
        @presenter.presentables[:__verifier] = @connection.verifier
        @presenter.presentables[:__authenticity_client_id] = authenticity_client_id
        @presenter.presentables[:__endpoint] = @connection.endpoint.deep_dup
        # TODO: should this be defined here since the base renderer knows nothing about modes?
        @presenter.presentables[:__mode] = @mode
        @presenter.presentables[:__params] = @connection.params
        @presenter.presentables[:__embed_authenticity_token] = @connection.app.config.presenter.embed_authenticity_token
        @presenter.presentables[:__csrf_param] = @connection.app.config.security.csrf.param
        call(self)
      end

      def serialize
        raise "serialize is not implemented on #{self}"
      end

      def rendering_prototype?
        Pakyow.env?(:prototype)
      end

      def to_html
        @presenter.to_html
      end
      alias to_s to_html

      private

      def dispatch
        performing :render do
          @presenter.call
        end
      end

      def find_presenter(path = nil)
        unless path.nil? || Pakyow.env?(:prototype)
          Templates.collapse_path(path) do |collapsed_path|
            if presenter = presenter_for_path(collapsed_path)
              return presenter
            end
          end
        end

        @connection.app.isolated(:Presenter)
      end

      private

      def presenter_for_path(path)
        @connection.app.state(:presenter).find { |presenter|
          presenter.path == path
        }
      end

      # We still mark endpoints as active when running in the prototype environment, but we don't
      # want to replace anchor hrefs, form actions, etc with backend routes. This gives the designer
      # control over how the prototype behaves.
      #
      def endpoints_for_environment
        if rendering_prototype?
          Endpoints.new
        else
          @connection.app.endpoints
        end
      end
    end
  end
end
