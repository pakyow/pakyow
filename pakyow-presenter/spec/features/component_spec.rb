RSpec.describe "defining the same component twice" do
  include_context "app"

  let :app_def do
    Proc.new do
      component :post do
      end

      component :post do
      end
    end
  end

  it "does not create a second object" do
    expect(Pakyow.apps.first.state(:component).count).to eq(1)
  end
end
