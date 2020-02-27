RSpec.describe "using an unknown subscribers adapter" do
  include_context "app"

  let :app_def do
    Proc.new do
      Pakyow.config.data.subscriptions.adapter = :foo
    end
  end

  let(:autorun) {
    false
  }

  it "raises an error" do
    expect {
      setup_and_run
    }.to raise_error(Pakyow::ApplicationError) do |error|
      expect(error.cause).to be_instance_of(Pakyow::Data::UnknownSubscriberAdapter)
      expect(error.message).to eq("failed to load subscriber adapter named `foo'")
    end
  end
end
