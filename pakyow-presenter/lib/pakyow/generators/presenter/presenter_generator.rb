# frozen_string_literal: true

require "pakyow/generator"

module Pakyow
  # @api private
  module Generators
    class Presenter < Generator
      def self.source_root
        File.expand_path("../", __FILE__)
      end

      argument :app
      argument :name
      argument :view_path

      def create_presenter
        template("templates/presenter.rb.tt", File.join(app.config.app.src, "presenters/#{name}_presenter.rb"))
      end

      protected

      def normalized_view_path
        File.join("/", view_path)
      end
    end
  end
end
