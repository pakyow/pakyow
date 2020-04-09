RSpec.describe "environment rescuing" do
  include_context "app"

  let(:autorun) {
    false
  }

  let(:allow_environment_errors) {
    true
  }

  let(:allow_request_failures) {
    true
  }

  context "environment is rescued" do
    def rescue!
      allow(Pakyow.logger).to receive(:houston)
      Pakyow.rescue!(error)
      setup_and_run
    end

    before do
      rescue!
    end

    let(:error) {
      begin
        fail "this is a test"
      rescue => error
        error
      end
    }

    it "reports the error" do
      expect(Pakyow.logger).to have_received(:houston).with(error)
    end

    it "appears to be rescued" do
      expect(Pakyow.rescued?).to be(true)
    end

    it "exposes the error" do
      expect(Pakyow.rescued).to be(error)
    end

    it "responds 500 to any request" do
      expect(call("/")[0]).to eq(500)
      expect(call("/foo/tfwayn")[0]).to eq(500)
    end

    describe "calling handlers" do
      def rescue!
        allow(Pakyow.logger).to receive(:houston)
        setup(env: mode)
        Pakyow.rescue!(error)
        run
      end

      let(:env_def) {
        Proc.new {
          handle 500 do |connection:|
            connection.body = "handled #{connection.error}"
            connection.halt
          end
        }
      }

      it "calls 500 handlers on the environment" do
        expect(call("/")[2]).to eq("handled this is a test")
      end
    end
  end
end
