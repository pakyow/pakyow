RSpec.describe "defining an application accept method" do
  include_context "app"

  let(:app_def) {
    Proc.new {
      def accept?(connection)
        connection.params.include?(:acceptable)
      end

      action do |connection|
        connection.body = "accepted"
        connection.halt
      end
    }
  }

  it "is called when the connection is acceptable" do
    expect(call("/", params: { acceptable: true })[2]).to eq("accepted")
  end

  it "is called when the connection is not acceptable" do
    expect(call("/")[2]).to eq("404 Not Found")
  end
end
