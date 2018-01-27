RSpec.describe "extending a controller without an extension" do
  include_context "testable app"

  let :app_definition do
    Proc.new {
      controller :admin, "/admin" do
        action :require_admin

        def require_admin
          $calls << :require_admin
        end
      end

      extend_controller :admin do
        resource :post, "/posts" do
          list do
            $calls << :list
          end
        end
      end
    }
  end

  before do
    $calls = []
  end

  it "extends the controller" do
    expect(call("/admin/posts")[0]).to eq(200)
    expect($calls[0]).to eq(:require_admin)
    expect($calls[1]).to eq(:list)
  end
end
