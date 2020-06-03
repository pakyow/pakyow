RSpec.describe "configuring a release channel that is unknown" do
  include_context "app"

  let(:autorun) {
    false
  }

  let(:env_def) {
    Proc.new {
      config.channel = :foo
    }
  }

  it "raises Pakyow::UnknownReleaseChannel" do
    expect {
      setup
    }.to raise_error(Pakyow::EnvironmentError) do |error|
      expect(error.cause).to be_instance_of(Pakyow::UnknownReleaseChannel)
      expect(error.message).to eq("`foo' is not a known release channel")
    end
  end

  it "includes a contextual message" do
    expect {
      setup
    }.to raise_error(Pakyow::EnvironmentError) do |error|
      expect(error.cause.contextual_message).to eq_sans_whitespace(
        <<~ERROR
          Try using one of these available release channels:

            - :default
            - :alpha
            - :beta
        ERROR
      )
    end
  end
end
