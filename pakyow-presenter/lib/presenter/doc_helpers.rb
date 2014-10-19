module Pakyow
  module Presenter
    module DocHelpers
      def self.self_closing_tag?(tag)
        %w[area base basefont br hr input img link meta].include? tag
      end

      def self.form_field?(tag)
        %w[input select textarea button].include? tag
      end

      def self.tag_without_value?(tag)
        %w[select].include? tag
      end
    end
  end
end
