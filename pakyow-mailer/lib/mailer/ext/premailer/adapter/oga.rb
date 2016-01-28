require 'oga'

module Oga
  module XML
    class Document
      # Premailer builds its css searches with `@` prepended to an attribute,
      # which breaks Oga. Since Premailer also expects `search` to be defined
      # on a document, we define it and just strip the `@` out before calling
      # Oga's build-in #css method.
      def search(query)
        css(query.gsub('@', ''))
      end
    end
  end
end

class Premailer
  # This method was tied to a specific type of document rather than being
  # adapter-agnostic (honestly it's a stretch to call them adapters). So,
  # we just pulled this method in and made it work w/ Oga.
  def load_css_from_html! # :nodoc:
    tags = @doc.css("link[rel='stylesheet']").reject { |tag|
      tag.attributes['data-premailer'] == 'ignore'
    }

    if tags
      tags.each do |tag|
        if tag.to_s.strip =~ /^\<link/i && tag.attributes['href'] && media_type_ok?(tag.attributes['media']) && @options[:include_link_tags]
          # A user might want to <link /> to a local css file that is also mirrored on the site
          # but the local one is different (e.g. newer) than the live file, premailer will now choose the local file

          if tag.attributes['href'].to_s.include? @base_url.to_s and @html_file.kind_of?(String)
            if @options[:with_html_string]
              link_uri = tag.attributes['href'].to_s.sub(@base_url.to_s, '')
            else
              link_uri = File.join(File.dirname(@html_file), tag.attributes['href'].to_s.sub!(@base_url.to_s, ''))
              # if the file does not exist locally, try to grab the remote reference
              unless File.exists?(link_uri)
                link_uri = Premailer.resolve_link(tag.attributes['href'].to_s, @html_file)
              end
            end
          else
            link_uri = tag.attributes['href'].to_s
          end

          if Premailer.local_data?(link_uri)
            $stderr.puts "Loading css from local file: " + link_uri if @options[:verbose]
            load_css_from_local_file!(link_uri)
          else
            $stderr.puts "Loading css from uri: " + link_uri if @options[:verbose]
            @css_parser.load_uri!(link_uri, {:only_media_types => [:screen, :handheld]})
          end

        elsif tag.to_s.strip =~ /^\<style/i && @options[:include_style_tags]
          @css_parser.add_block!(tag.inner_html, :base_uri => @base_url, :base_dir => @base_dir, :only_media_types => [:screen, :handheld])
        end
      end
      unless @options[:preserve_styles]
        tags.each do |tag|
          tag.remove
        end
      end
    end
  end

  module Adapter
    # Oga adapter
    module Oga

      # Merge CSS into the HTML document.
      #
      # @return [String] an HTML.
      def to_inline_css
        doc = @processed_doc
        @unmergable_rules = CssParser::Parser.new

        # Give all styles already in style attributes a specificity of 1000
        # per http://www.w3.org/TR/CSS21/cascade.html#specificity
        doc.css("*[style]").each do |el|
          el['style'] = '[SPEC=1000[' + el.attributes['style'] + ']]'
        end
        # Iterate through the rules and merge them into the HTML
        @css_parser.each_selector(:all) do |selector, declaration, specificity, media_types|
          # Save un-mergable rules separately
          selector.gsub!(/:link([\s]*)+/i) { |m| $1 }

          # Convert element names to lower case
          selector.gsub!(/([\s]|^)([\w]+)/) { |m| $1.to_s + $2.to_s.downcase }

          if Premailer.is_media_query?(media_types) || selector =~ Premailer::RE_UNMERGABLE_SELECTORS
            @unmergable_rules.add_rule_set!(CssParser::RuleSet.new(selector, declaration), media_types) unless @options[:preserve_styles]
          else
            begin
              if selector =~ Premailer::RE_RESET_SELECTORS
                # this is in place to preserve the MailChimp CSS reset: http://github.com/mailchimp/Email-Blueprints/
                # however, this doesn't mean for testing pur
                @unmergable_rules.add_rule_set!(CssParser::RuleSet.new(selector, declaration)) unless !@options[:preserve_reset]
              end

              # Change single ID CSS selectors into xpath so that we can match more
              # than one element.  Added to work around dodgy generated code.
              selector.gsub!(/\A\#([\w_\-]+)\Z/, '*[@id=\1]')

              doc.css(selector).each do |el|
                if el.elem? and (el.name != 'head' and el.parent.name != 'head')
                  # Add a style attribute or append to the existing one
                  block = "[SPEC=#{specificity}[#{declaration}]]"
                  el['style'] = (el.attributes['style'].to_s ||= '') + ' ' + block
                end
              end
            rescue RuntimeError, ArgumentError
              $stderr.puts "CSS syntax error with selector: #{selector}" if @options[:verbose]
              next
            end
          end
        end

        # Remove script tags
        if @options[:remove_scripts]
          doc.css("script").remove
        end

        # Read STYLE attributes and perform folding
        doc.css("*[style]").each do |el|
          style = el.attributes['style'].to_s

          declarations = []
          style.scan(/\[SPEC\=([\d]+)\[(.[^\]\]]*)\]\]/).each do |declaration|
            rs = CssParser::RuleSet.new(nil, declaration[1].to_s, declaration[0].to_i)
            declarations << rs
          end

          # Perform style folding
          merged = CssParser.merge(declarations)
          merged.expand_shorthand!

          # Duplicate CSS attributes as HTML attributes
          if Premailer::RELATED_ATTRIBUTES.has_key?(el.name) && @options[:css_to_attributes]
            Premailer::RELATED_ATTRIBUTES[el.name].each do |css_att, html_att|
              el[html_att] = merged[css_att].gsub(/url\(['|"](.*)['|"]\)/, '\1').gsub(/;$|\s*!important/, '').strip if el[html_att].nil? and not merged[css_att].empty?
              merged.instance_variable_get("@declarations").tap do |declarations|
                declarations.delete(css_att)
              end
            end
          end
          # Collapse multiple rules into one as much as possible.
          merged.create_shorthand! if @options[:create_shorthands]

          # write the inline STYLE attribute
          attributes = Premailer.escape_string(merged.declarations_to_s).split(';').map(&:strip)
          attributes = attributes.map { |attr| [attr.split(':').first, attr] }.sort_by { |pair| pair.first }.map { |pair| pair[1] }
          el['style'] = attributes.join('; ')
        end

        doc = write_unmergable_css_rules(doc, @unmergable_rules)

        if @options[:remove_classes] or @options[:remove_comments]
          doc.traverse do |el|
            if el.comment? and @options[:remove_comments]
              el.remove
            elsif el.element?
              el.remove_attribute('class') if @options[:remove_classes]
            end
          end
        end

        if @options[:remove_ids]
          # find all anchor's targets and hash them
          targets = []
          doc.css("a[@href^='#']").each do |el|
            target = el.get_attribute('href')[1..-1]
            targets << target
            el.set_attribute('href', "#" + Digest::MD5.hexdigest(target))
          end
          # hash ids that are links target, delete others
          doc.css("*[@id]").each do |el|
            id = el.get_attribute('id')
            if targets.include?(id)
              el.set_attribute('id', Digest::MD5.hexdigest(id))
            else
              el.remove_attribute('id')
            end
          end
        end

        if @options[:reset_contenteditable]
          doc.css('*[contenteditable]').each do |el|
            el.remove_attribute('contenteditable')
          end
        end

        @processed_doc = doc
        @processed_doc.to_xml
      end

      # Create a <tt>style</tt> element with un-mergable rules (e.g. <tt>:hover</tt>)
      # and write it into the <tt>body</tt>.
      #
      # <tt>doc</tt> is an Oga document and <tt>unmergable_css_rules</tt> is a Css::RuleSet.
      #
      # @return [::Oga::XML::Document] a document.
      def write_unmergable_css_rules(doc, unmergable_rules) # :nodoc:
        styles = unmergable_rules.to_s

        unless styles.empty?
          style_tag = "<style type=\"text/css\">\n#{styles}</style>"
          unless (body = doc.css('body')).empty?
            if doc.at_css('body').children && !doc.at_css('body').children.empty?
              doc.at_css('body').children.before(::Oga.parse_html(style_tag))
            else
              doc.at_css('body').add_child(::Oga.parse_html(style_tag))
            end
          else
            doc.inner_html = style_tag += doc.inner_html
          end
        end
        doc
      end


      # Converts the HTML document to a format suitable for plain-text e-mail.
      #
      # If present, uses the <body> element as its base; otherwise uses the whole document.
      #
      # @return [String] a plain text.
      def to_plain_text
        html_src = ''
        begin
          html_src = @doc.at("body").inner_html
        rescue;
        end

        html_src = @doc.to_xml unless html_src and not html_src.empty?
        convert_to_text(html_src, @options[:line_length], @html_encoding)
      end

      # Gets the original HTML as a string.
      # @return [String] HTML.
      def to_s
        @doc.to_xml
      end

      # Load the HTML file and convert it into an Oga document.
      #
      # @return [::Oga::XML::Document] a document.
      def load_html(input) # :nodoc:
        thing = nil

        # TODO: duplicate options
        if @options[:with_html_string] or @options[:inline] or input.respond_to?(:read)
          thing = input
        elsif @is_local_file
          @base_dir = File.dirname(input)
          thing = File.open(input, 'r')
        else
          thing = open(input)
        end

        ::Oga.parse_html(thing)
      end
    end
  end
end
