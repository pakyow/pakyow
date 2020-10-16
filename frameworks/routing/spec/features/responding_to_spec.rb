RSpec.describe "responding to request format" do
  include_context "app"

  let :app_def do
    Proc.new {
      controller do
        get "foo.txt|html" do
          respond_to :txt do
            connection.body = StringIO.new("foo")
          end

          connection.body = StringIO.new("<foo>")
        end
      end
    }
  end

  it "responds properly" do
    expect(call("/foo.txt")[2]).to eq("foo")
    expect(call("/foo.html")[2]).to eq("<foo>")
  end

  it "responds 404 to unsupported extensions" do
    expect(call("/foo.bar")[0]).to eq(404)
  end

  context "route does not exist" do
    it "responds 404" do
      expect(call("/bar")[0]).to eq(404)
      expect(call("/bar.txt")[0]).to eq(404)
    end
  end
end
