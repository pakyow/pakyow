RSpec.describe "defining the same presenter twice" do
  include_context "app"

  let :app_def do
    Proc.new do
      presenter :post do
        render do
        end
      end

      presenter :post do
        render do
        end
      end
    end
  end

  it "does not create a second object" do
    expect(Pakyow.apps.first.state(:presenter).count).to eq(1)
  end

  it "extends the first object" do
    expect(
      Pakyow.apps.first.state(:presenter)[0].__attached_renders.select { |render|
        render[:block].source_location.to_s.include?("presenter_spec.rb")
      }.count
    ).to eq(2)
  end
end
