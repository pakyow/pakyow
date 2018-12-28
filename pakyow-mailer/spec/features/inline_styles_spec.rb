RSpec.describe "inlining styles" do
  include_context "app"

  after do
    $sent = nil
  end

  context "mailing with presenter" do
    let :app_definition do
      Proc.new do
        instance_exec(&$mailer_app_boilerplate)

        controller "/mail" do
          get "/send" do
            $sent = mailer("mail/styled").deliver_to(
              "bryan@bryanp.org"
            )

            halt
          end
        end
      end
    end

    it "inlines styles from the stylesheet" do
      response = call("/mail/send")
      expect(response[0]).to eq(200)

      doc = Oga.parse_html($sent.first.body.parts.find { |part|
        part.content_type.to_s.include?("text/html")
      }.body.to_s)

      expect(doc.children.first[:style]).to include("color: red; font-weight: bold")
    end

    it "does not overwrite existing style value" do
      response = call("/mail/send")
      expect(response[0]).to eq(200)

      doc = Oga.parse_html($sent.first.body.parts.find { |part|
        part.content_type.to_s.include?("text/html")
      }.body.to_s)

      expect(doc.children.first[:style]).to include("font-style: italic")
    end
  end
end
