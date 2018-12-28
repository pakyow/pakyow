RSpec.describe "logging outgoing mail" do
  include_context "app"

  context "logging is enabled" do
    let :app_definition do
      Proc.new do
        instance_exec(&$mailer_app_boilerplate)

        configure :test do
          config.mailer.silent = false
        end

        controller "/mail" do
          get "/send/:email/:subject" do
            params[:email].gsub!("__", ".")
            mailer("mail/simple").deliver_to(
              params[:email], subject: params[:subject]
            )

            halt
          end
        end
      end
    end

    it "logs" do
      expect_any_instance_of(Pakyow::Logger::RequestLogger).to receive(:debug).with <<~LOG
      ┌──────────────────────────────────────────────────────────────────────────────┐
      │ Subject: logtest                                                             │
      ├──────────────────────────────────────────────────────────────────────────────┤
      │ test mail                                                                    │
      ├──────────────────────────────────────────────────────────────────────────────┤
      │ → bryan@bryanp.org                                                           │
      └──────────────────────────────────────────────────────────────────────────────┘
      LOG

      expect(call("/mail/send/bryan@bryanp__org/logtest")[0]).to eq(200)
    end
  end

  context "logging is disabled" do
    let :app_definition do
      Proc.new do
        instance_exec(&$mailer_app_boilerplate)

        configure :test do
          config.mailer.silent = true
        end

        controller "/mail" do
          get "/send/:email/:subject" do
            params[:email].gsub!("__", ".")
            mailer("mail/simple").deliver_to(
              params[:email], subject: params[:subject]
            )

            halt
          end
        end
      end
    end

    it "does not log" do
      expect_any_instance_of(Pakyow::Logger::RequestLogger).not_to receive(:debug)
      expect(call("/mail/send/bryan@bryanp__org/logtest")[0]).to eq(200)
    end
  end
end
