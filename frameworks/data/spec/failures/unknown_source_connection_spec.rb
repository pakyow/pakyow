RSpec.describe "defining a source for an unknown connection" do
  include_context "app"

  let :app_def do
    Proc.new do
      source :posts, connection: :foo do; end
    end
  end

  let(:autorun) {
    false
  }

  it "raises an error" do
    expect {
      setup_and_run
    }.to raise_error(Pakyow::ApplicationError) do |error|
      expect(error.message).to eq("`foo' is not a known database connection for the sql adapter")
    end
  end
end
