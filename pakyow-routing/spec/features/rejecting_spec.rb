RSpec.describe "rejecting requests" do
  include_context "app"

  context "when rejecting from a route" do
    let :app_init do
      Proc.new {
        controller do
          default do
            reject
            $one = true
          end
        end

        controller do
          default do
            $two = true
          end
        end
      }
    end

    before do
      $one = false
      $two = false
    end

    it "processes the unrejected route" do
      call
      expect($one).to be(false)
      expect($two).to be(true)
    end
  end
end
