RSpec.describe "app rescuing" do
  include_context "app"

  let(:allow_application_rescues) { true }

  context "app boots in rescue mode" do
    let(:app_def) {
      Proc.new {
        fail "failed to boot app"
      }
    }

    it "responds 500 to any request" do
      expect(call("/")[0]).to eq(500)
      expect(call("/foo/tfwayn")[0]).to eq(500)
    end

    it "responds with the error" do
      expect(call("/")[2]).to include(
        <<~ERROR
          Test::Application failed to initialize.

          failed to boot app
        ERROR
      )
    end
  end

  context "app fails during setup" do
    let(:app_def) {
      Proc.new {
        attr_reader :fully_initialized

        on "setup" do
          fail
        end

        on "initialize" do
          @fully_initialized = true
        end
      }
    }

    it "is rescued" do
      expect(Pakyow.app(:test).rescued?).to be(true)
    end

    it "partially initializes" do
      expect(Pakyow.app(:test).mount_path).to eq("/")
    end

    it "does not fully initialize" do
      expect(Pakyow.app(:test).fully_initialized).not_to be(true)
    end
  end
end
