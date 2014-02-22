module Pakyow
  module Presenter
    module TitleHelpers
      def title=(title)
        return if @doc.nil?

        if o = @doc.css('title').first
          o.inner_html = Nokogiri::HTML::fragment(title.to_s)
        elsif o = @doc.css('head').first
          o.add_child(Nokogiri::HTML::fragment("<title>#{title}</title>"))
        end
      end

      def title
        return unless o = @doc.css('title').first
        o.inner_text
      end
    end
  end
end

