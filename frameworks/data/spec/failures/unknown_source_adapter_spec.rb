RSpec.describe "defining a source for an unknown adapter" do
  include_context "app"

  let :app_def do
    Proc.new do
      source :posts, adapter: :foo do; end
    end
  end

  let(:autorun) {
    false
  }

  it "raises an error" do
    expect {
      setup_and_run
    }.to raise_error(Pakyow::ApplicationError) do |error|
      expect(error.cause).to be_instance_of(Pakyow::Data::UnknownAdapter)
      expect(error.message).to eq("`foo' is not a known adapter")
    end
  end
end
