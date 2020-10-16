RSpec.describe "making an application" do
  describe "the isolated connection" do
    it "is available when making an app" do
      connection = nil
      Pakyow::Application.make :test do
        connection = isolated(:Connection)
      end

      expect(connection).to be(Test::Connection)
    end
  end
end
