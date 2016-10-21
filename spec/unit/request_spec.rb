RSpec.describe Pakyow::Request do
  include Pakyow::SpecHelpers::MockRequest

  before do
    @request = mock_request(:get, "/foo", { "HTTP_REFERER" => "/bar" })
  end

  it "extends rack request" do
    expect(Pakyow::Request.superclass).to eq Rack::Request
  end

  it "path calls path info" do
    expect(@request.path).to eq @request.path_info
  end

  it "method is proper format" do
    expect(@request.method).to eq :get
  end
end
