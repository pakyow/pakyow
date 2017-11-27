RSpec.describe "proc hooks" do
  include_context "testable app"

  before do
    $calls = []; call
  end

  context "when a hook is defined as a proc on a route" do
    let :app_definition do
      Proc.new do
        router do
          default before: -> { $calls << :before } do
            $calls << :route
          end
        end
      end
    end

    it "is called" do
      expect($calls[0]).to eq(:before)
    end
  end

  context "when a hook is defined as a proc on a router" do
    let :app_definition do
      Proc.new do
        router before: -> { $calls << :before } do
          default do
            $calls << :route
          end
        end
      end
    end

    it "is called" do
      expect($calls[0]).to eq(:before)
    end
  end
end
