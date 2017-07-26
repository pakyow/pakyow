RSpec.describe "halting a request" do
  include_context "testable app"

  context "when halting from a route" do
    let :app_definition do
      Proc.new {
        router do
          default do
            $called = true
            halt
            $halted = false
          end
        end
      }
    end

    before do
      $called = false
      $halted = true
    end

    it "immediately halts and returns the response" do
      call
      expect($called).to be(true)
      expect($halted).to be(true)
    end
  end

  context "when halting from a hook" do
    let :app_definition do
      Proc.new {
        router do
          def hook
            $hooked = true
            halt
          end

          default before: [:hook] do
            $halted = false
          end
        end
      }
    end

    before do
      $hooked = false
      $halted = true
    end

    it "immediately halts and returns the response" do
      call
      expect($hooked).to be(true)
      expect($halted).to be(true)
    end
  end
end
