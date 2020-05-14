RSpec.describe "running a runnable container with a formation referencing an unknown service" do
  include_context "app"

  it "raises Pakyow::UnknownService" do
    expect {
      Pakyow.run formation: Pakyow::Runnable::Formation.parse("environment.foo=1")
    }.to raise_error(Pakyow::UnknownService, "`foo' is not a known service in the `environment' container")
  end

  it "includes a contextual message" do
    begin
      Pakyow.run formation: Pakyow::Runnable::Formation.parse("environment.foo=1")
    rescue Pakyow::UnknownService => error
      expect(error.contextual_message).to eq_sans_whitespace(
        <<~MESSAGE
          Try using one of these available services:

            - :server
        MESSAGE
      )
    end
  end
end
