RSpec.describe "mounting an app at a path" do
  include_context "app"

  let :autorun do
    false
  end

  before do
    Pakyow.app :test1, path: "/test1" do
      action :test do |connection|
        connection.body = StringIO.new("#{self.class}: #{connection.path}")
        connection.halt
      end
    end

    Pakyow.app :test2, path: "/test2" do
      action :test do |connection|
        connection.body = StringIO.new("#{self.class}: #{connection.path}")
        connection.halt
      end
    end

    setup_and_run
  end

  it "calls the app matching the request path" do
    expect(call("/test2")[2]).to include("Test2::Application")
  end

  it "calls the app that starts with the request path" do
    expect(call("/test1/foo")[2]).to include("Test1::Application")
  end

  describe "connection path" do
    it "is relative to the app path" do
      expect(call("/test1/foo")[2]).to eq("Test1::Application: /foo")
    end
  end
end
