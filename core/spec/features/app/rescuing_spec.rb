RSpec.describe "app rescuing" do
  include_context "app"

  let(:autorun) {
    false
  }

  let(:allow_application_rescues) {
    true
  }

  context "app is rescued" do
    def rescue!
      allow(Pakyow.logger).to receive(:houston)
      app.rescue!(error)
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
      expect(app.rescued?).to be(true)
    end

    it "exposes the error" do
      expect(app.rescued).to be(error)
    end

    it "responds 500 to any request" do
      expect(call("/")[0]).to eq(500)
      expect(call("/foo/tfwayn")[0]).to eq(500)
    end

    describe "calling hooks" do
      before do
        Pakyow.app(:test).shutdown
      end

      let(:app_def) {
        local = self
        Proc.new {
          before "initialize" do
            local.calls << "before initialize"
          end

          after "initialize" do
            local.calls << "after initialize"
          end

          before "boot" do
            local.calls << "before boot"
          end

          after "boot" do
            local.calls << "after boot"
          end

          before "shutdown" do
            local.calls << "before shutdown"
          end

          after "shutdown" do
            local.calls << "after shutdown"
          end
        }
      }

      let(:calls) {
        []
      }

      it "does not call initialize hooks" do
        expect(calls).not_to include("before initialize")
        expect(calls).not_to include("after initialize")
      end

      it "does not call boot hooks" do
        expect(calls).not_to include("before boot")
        expect(calls).not_to include("after boot")
      end

      it "does not call shutdown hooks" do
        expect(calls).not_to include("before shutdown")
        expect(calls).not_to include("after shutdown")
      end
    end

    describe "calling handlers" do
      def rescue!
        allow(Pakyow.logger).to receive(:houston)
        setup(env: mode)
        app.rescue!(error)
        run
      end

      let(:app_def) {
        Proc.new {
          handle 500 do |connection:|
            connection.body = "handled #{connection.error}"
            connection.halt
          end
        }
      }

      it "calls 500 handlers on the application" do
        expect(call("/")[2]).to eq("handled this is a test")
      end
    end
  end
end
