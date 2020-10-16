RSpec.describe "logging outgoing mail" do
  include_context "app"

  context "logging is enabled" do
    let :app_def do
      Proc.new do
        configure :test do
          config.mailer.silent = false
        end
      end
    end

    let :app_def do
      Proc.new do
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

    let :logger_io do
      StringIO.new
    end

    it "logs" do
      allow_any_instance_of(Pakyow::Logger).to receive(:debug) do |logger, message|
        if logger.type == :http
          expect(message).to eq(
            <<~LOG
              ┌──────────────────────────────────────────────────────────────────────────────┐
              │ Subject: logtest                                                             │
              ├──────────────────────────────────────────────────────────────────────────────┤
              │ test mail                                                                    │
              ├──────────────────────────────────────────────────────────────────────────────┤
              │ → bryan@bryanp.org                                                           │
              └──────────────────────────────────────────────────────────────────────────────┘
            LOG
          )
        end
      end

      expect(call("/mail/send/bryan@bryanp__org/logtest")[0]).to eq(200)
    end
  end

  context "logging is disabled" do
    let :app_def do
      Proc.new do
        configure :test do
          config.mailer.silent = true
        end
      end
    end

    let :app_def do
      Proc.new do
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
      allow_any_instance_of(Pakyow::Logger).to receive(:debug) do |logger, message|
        if logger.type == :http
          fail "did not expect to log"
        end
      end

      expect(call("/mail/send/bryan@bryanp__org/logtest")[0]).to eq(200)
    end
  end
end
