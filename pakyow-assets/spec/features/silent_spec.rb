RSpec.describe "silencing requests" do
  let :io do
    StringIO.new
  end

  let :logger do
    require "pakyow/logger/formatters/human"
    Pakyow::RequestLogger.new(:http, logger: Pakyow::Logger.new(io).tap { |logger| logger.formatter = Pakyow::Logger::Formatters::Human.new })
  end

  before do
    Pakyow.silencers.clear
    allow(Pakyow::RequestLogger).to receive(:new).and_return(logger)
  end

  include_context "app"

  context "request is for an asset" do
    context "silent is enabled" do
      let :app_def do
        Proc.new do
          config.assets.silent = true
        end
      end

      it "does not log the asset request" do
        call("/assets/foo.bar")
        expect(io.string).to be_empty
      end

      it "does log a non-asset request" do
        call("/foo.bar")
        expect(io.string).not_to be_empty
      end
    end

    context "silent is disabled" do
      let :app_def do
        Proc.new do
          configure do
            config.assets.silent = false
          end
        end
      end

      it "logs the asset request" do
        call("/assets/foo.bar")
        expect(io.string).not_to be_empty
      end
    end
  end

  context "request is for a public file" do
    context "silent is enabled" do
      let :app_def do
        Proc.new do
          config.assets.silent = true
          config.assets.public_path = File.expand_path("../", __FILE__)
        end
      end

      it "does not log the public request" do
        call("/silent_spec.rb")
        expect(io.string).to be_empty
      end

      it "does log a non-public request" do
        call("/foo.bar")
        expect(io.string).not_to be_empty
      end
    end

    context "silent is disabled" do
      let :app_def do
        Proc.new do
          config.assets.silent = false
          config.assets.public_path = File.expand_path("../", __FILE__)
        end
      end

      it "logs the public request" do
        call("/silent_spec.rb")
        expect(io.string).not_to be_empty
      end
    end
  end
end
