RSpec.describe "silencing requests" do
  let :io do
    StringIO.new
  end

  before do
    Pakyow.silencers.clear

    Pakyow.after :configure do
      config.logger.enabled = true
    end
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
        expect(Pakyow.global_logger).not_to receive(:call)
        call("/assets/foo.bar")
      end

      it "does log a non-asset request" do
        expect(Pakyow.global_logger).to receive(:call).at_least(:once)
        call("/foo.bar.baz")
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
        expect(Pakyow.global_logger).to receive(:call).at_least(:once)
        call("/assets/foo.bar")
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
        expect(Pakyow.global_logger).not_to receive(:call)
        call("/silent_spec.rb")
      end

      it "does log a non-public request" do
        expect(Pakyow.global_logger).to receive(:call).at_least(:once)
        call("/foo.bar")
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
        expect(Pakyow.global_logger).to receive(:call).at_least(:once)
        call("/silent_spec.rb")
      end
    end
  end
end
