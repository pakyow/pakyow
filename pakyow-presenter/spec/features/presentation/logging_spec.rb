RSpec.describe "logging within a presenter" do
  include_context "app"

  let :app_init do
    Proc.new do
      presenter "/" do
        def perform
          $logger = logger
        end
      end
    end
  end

  after do
    $logger = nil
  end

  it "exposes the connection logger" do
    expect(call("/")[2]).to include_sans_whitespace(
      <<~HTML
        index
      HTML
    )

    expect($logger).to be_instance_of(Pakyow::Logger)
    expect($logger.type).to eq(:http)
  end
end
