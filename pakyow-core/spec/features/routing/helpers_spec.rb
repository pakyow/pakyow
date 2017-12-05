RSpec.describe "application helpers" do
  include_context "testable app"

  module Pakyow::Helpers
    def foo
      "foo"
    end
  end

  let :app_definition do
    Proc.new {
      controller do
        default do
          send foo
        end
      end
    }
  end

  it "makes helpers available within a controller" do
    expect(call[2].body.read).to eq("foo")
  end
end
