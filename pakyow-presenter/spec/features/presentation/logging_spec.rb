RSpec.describe "logging within a presenter" do
  include_context "testable app"

  let :app_definition do
    Proc.new {
      instance_exec(&$presenter_app_boilerplate)

      presenter "/" do
        def perform
          logger.debug "testing"
        end
      end
    }
  end

  it "writes to the log" do
    expect_any_instance_of(Pakyow::Logger::RequestLogger).to receive(:debug).with("testing")

    expect(call("/")[2].body.read).to include_sans_whitespace(
      <<~HTML
        index
      HTML
    )
  end
end
