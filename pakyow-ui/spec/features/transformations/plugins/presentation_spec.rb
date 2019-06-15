require "pakyow/plugin"

RSpec.describe "presenting data from a plugin" do
  before do
    class TestPlugin < Pakyow::Plugin(:testable, File.join(__dir__, "support/plugin"))
    end
  end

  after do
    Object.send(:remove_const, :TestPlugin)
  end

  include_context "app"

  let :app_def do
    Proc.new do
      plug :testable, at: "/"

      configure do
        config.root = File.join(__dir__, "support/app")
      end
    end
  end

  include_context "websocket intercept"

  it "transforms" do |x|
    call("/posts", method: :post, params: { post: { title: "foo" } })
    call("/posts", method: :post, params: { post: { title: "bar" } })

    save_ui_case(x, path: "/posts") do
      call("/posts", method: :post, params: { post: { title: "baz" } })
    end
  end

  context "using a view from the app" do
    it "transforms" do |x|
      call("/posts", method: :post, params: { post: { title: "foo" } })
      call("/posts", method: :post, params: { post: { title: "bar" } })

      save_ui_case(x, path: "/posts/app") do
        call("/posts", method: :post, params: { post: { title: "baz" } })
      end
    end
  end
end
