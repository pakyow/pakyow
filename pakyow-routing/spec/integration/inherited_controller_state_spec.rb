RSpec.describe "inherited controller state" do
  include_context "app"

  describe "routes" do
    let :app_def do
      Proc.new {
        controller do
          default do
            connection.body = StringIO.new("one")
          end

          namespace "/foo" do
            default do
              connection.body = StringIO.new("two")
            end
          end
        end
      }
    end

    it "does not inherit" do
      expect(call("/foo")[2]).to eq("two")
    end
  end
end
