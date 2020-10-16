require "pakyow/plugin"

RSpec.describe "plugin connection" do
  before do
    class TestPlugin < Pakyow::Plugin(:testable, File.join(__dir__, "support/plugin"))
      action :test

      def test(connection)
        connection.body = StringIO.new(
          Marshal.dump(
            connection_class: connection.class,
            connection_verifier_key: connection.verifier.key
          )
        )

        connection.halt
      end
    end
  end

  include_context "app"

  let :app_def do
    Proc.new do
      plug :testable
    end
  end

  let :result do
    Marshal.load(call("/")[2])
  end

  it "is a plugin connection" do
    expect(result[:connection_class]).to eq(Test::Testable::Default::Connection)
  end

  describe "connection verifier" do
    it "has the a verifier with a key" do
      expect(result[:connection_verifier_key]).to_not be(nil)
    end
  end
end
