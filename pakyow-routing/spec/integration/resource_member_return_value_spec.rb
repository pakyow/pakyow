RSpec.describe "return value from resource member definition" do
  include_context "app"

  let :app_def do
    Proc.new do
      resource :posts, "/posts" do
        member do; end
      end
    end
  end

  let :resource do
    Pakyow.app(:test).controllers.definitions[0]
  end

  it "returns the member" do
    expect(resource.children[0].name).to eq("Test::Controllers::Posts::Member")
  end
end
