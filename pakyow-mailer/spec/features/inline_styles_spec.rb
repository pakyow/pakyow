RSpec.describe "inlining styles" do
  include_context "app"

  after do
    $sent = nil
  end

  context "mailing with presenter" do
    let :app_def do
      Proc.new do
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

      expect($sent.first.body.parts.find { |part|
        part.content_type.to_s.include?("text/html")
      }.body.to_s).to include("color: red; font-weight: bold;")
    end

    it "does not overwrite existing style value" do
      response = call("/mail/send")
      expect(response[0]).to eq(200)

      expect($sent.first.body.parts.find { |part|
        part.content_type.to_s.include?("text/html")
      }.body.to_s).to include("font-style: italic")
    end
  end
end
