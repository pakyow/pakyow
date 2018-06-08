RSpec.describe "sending mail" do
  include_context "testable app"

  after do
    $sent = nil
  end

  context "mailing with presenter" do
    let :app_definition do
      Proc.new do
        instance_exec(&$mailer_app_boilerplate)

        controller "/mail" do
          get "/send/many/:subject" do
            $sent = mailer("mail/simple").deliver_to(
              ["foo@bar.com", "baz@qux.com"], subject: params[:subject]
            )

            send "sent"
          end

          get "/send/:email/:subject" do
            params[:email].gsub!("__", ".")
            $sent = mailer("mail/simple").deliver_to(
              params[:email], subject: params[:subject]
            )

            send "sent"
          end
        end
      end
    end

    it "delivers" do
      expect_any_instance_of(
        Pakyow::Mailer::Mailer
      ).to receive(:deliver_to).with("bryan@bryanp.org", subject: "test123")
      response = call("/mail/send/bryan@bryanp__org/test123")
      expect(response[0]).to eq(200)
      expect(response[2].body.read).to eq("sent")
    end

    it "delivers to many recipients" do
      response = call("/mail/send/many/test123")
      expect(response[0]).to eq(200)
      expect(response[2].body.read).to eq("sent")

      expect($sent.count).to eq(2)
      expect($sent[0].to.first).to eq("foo@bar.com")
      expect($sent[1].to.first).to eq("baz@qux.com")
    end

    it "sets the html content" do
      call("/mail/send/bryan@bryanp__org/test123")

      expect(
        $sent.first.body.parts.find { |part|
          part.content_type.to_s.include?("text/html")
        }.to_s
      ).to include("test mail")
    end

    it "sets the text content" do
      call("/mail/send/bryan@bryanp__org/test123")

      expect(
        $sent.first.body.parts.find { |part|
          part.content_type.to_s.include?("text/plain")
        }.to_s
      ).to include("test mail")
    end

    it "sets the message subject" do
      call("/mail/send/bryan@bryanp__org/test123")
      expect($sent.first.subject).to eq("test123")
    end

    context "presenter is defined" do
      let :app_definition do
        Proc.new do
          instance_exec(&$mailer_app_boilerplate)

          controller "/mail" do
            get "/send/:email/:subject" do
              expose :user, { name: "Bob Dylan" }

              $sent = mailer("mail/with_bindings").deliver_to(
                params[:email], subject: params[:subject]
              )
            end
          end

          presenter "/mail/with_bindings" do
            perform do
              find(:user).present(user)
            end
          end
        end
      end

      it "renders the mail view with presenter" do
        call("/mail/send/bryan@bryanp__org/test123")

        expect(
          $sent.first.body.parts.find { |part|
            part.content_type.to_s.include?("text/html")
          }.to_s
        ).to include("Bob Dylan")
      end

      it "does not render the templates" do
        call("/mail/send/bryan@bryanp__org/test123")

        expect(
          $sent.first.body.parts.find { |part|
            part.content_type.to_s.include?("text/html")
          }.to_s
        ).not_to include("script")
      end
    end

    context "presenter is not defined" do
      let :app_definition do
        Proc.new do
          instance_exec(&$mailer_app_boilerplate)

          controller "/mail" do
            get "/send/:email/:subject" do
              expose :user, { name: "Bob Dylan" }

              $sent = mailer("mail/with_bindings").deliver_to(
                params[:email], subject: params[:subject]
              )
            end
          end
        end
      end

      it "renders automatically" do
        call("/mail/send/bryan@bryanp__org/test123")

        expect(
          $sent.first.body.parts.find { |part|
            part.content_type.to_s.include?("text/html")
          }.to_s
        ).to include("Bob Dylan")
      end

      it "does not render the templates" do
        call("/mail/send/bryan@bryanp__org/test123")

        expect(
          $sent.first.body.parts.find { |part|
            part.content_type.to_s.include?("text/html")
          }.to_s
        ).not_to include("script")
      end
    end

    context "mailing with a block" do
      let :app_definition do
        Proc.new do
          instance_exec(&$mailer_app_boilerplate)

          controller "/mail" do
            get "/send" do
              $sent = []

              users = [
                { name: "foo bar", email: "foo@bar.com" },
                { name: "baz qux", email: "baz@qux.com" }
              ]

              users.each do |user|
                mailer("mail/with_bindings") do |mailer|
                  expose :user, user
                  $sent.concat(mailer.deliver_to(user[:email]))
                end
              end

              send "sent"
            end
          end
        end
      end

      it "sends each version of the message" do
        call("/mail/send")

        expect($sent.count).to eq(2)

        expect(
          $sent[0].body.parts.find { |part|
            part.content_type.to_s.include?("text/plain")
          }.to_s
        ).to include("foo bar")

        expect(
          $sent[1].body.parts.find { |part|
            part.content_type.to_s.include?("text/plain")
          }.to_s
        ).to include("baz qux")
      end
    end
  end

  context "mailing without presenter" do
    let :app_definition do
      Proc.new do
        instance_exec(&$mailer_app_boilerplate)

        controller "/mail" do
          get "/send/:email/:subject" do
            $sent = mailer.deliver_to(
              params[:email], subject: params[:subject], content: "foo"
            )
          end
        end
      end
    end

    it "sends content as plaintext" do
      call("/mail/send/bryan@bryanp__org/test123")
      expect($sent.first.multipart?).to be(false)
      expect($sent.first.subject.to_s).to eq("test123")
      expect($sent.first.body.to_s).to eq("foo")
    end

    context "content is html" do
      let :app_definition do
        Proc.new do
          instance_exec(&$mailer_app_boilerplate)

          controller "/mail" do
            get "/send/:email/:subject" do
              $sent = mailer.deliver_to(
                params[:email], subject: params[:subject], content: "<p>foo</p>", type: "text/html"
              )
            end
          end
        end
      end

      it "sends a multipart email" do
        call("/mail/send/bryan@bryanp__org/test123")
        expect($sent.first.multipart?).to be(true)
      end

      it "sets the html content" do
        call("/mail/send/bryan@bryanp__org/test123")

        expect(
          $sent.first.body.parts.find { |part|
            part.content_type.to_s.include?("text/html")
          }.to_s
        ).to include("<p>foo</p>")
      end

      it "sets the text content" do
        call("/mail/send/bryan@bryanp__org/test123")

        expect(
          $sent.first.body.parts.find { |part|
            part.content_type.to_s.include?("text/plain")
          }.to_s
        ).to include("foo")
      end

      it "sets the message subject" do
        call("/mail/send/bryan@bryanp__org/test123")
        expect($sent.first.subject).to eq("test123")
      end
    end
  end
end
