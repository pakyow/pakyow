RSpec.describe "responding to request format" do
  include_context "testable app"

  let :app_definition do
    Proc.new {
      controller do
        get "foo.txt|html" do
          respond_to :txt do
            res.body = "foo"
          end

          res.body = "<foo>"
        end
      end
    }
  end

  it "responds properly" do
    expect(call("/foo.txt")[2].body).to eq("foo")
    expect(call("/foo.html")[2].body).to eq("<foo>")
  end
end
