RSpec.describe "rejecting requests" do
  include_context "testable app"

  context "when rejecting from a route" do
    let :app_definition do
      -> {
        router do
          default do
            reject
            $one = true
          end
        end

        router do
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
