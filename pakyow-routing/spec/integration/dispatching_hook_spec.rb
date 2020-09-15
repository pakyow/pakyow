RSpec.describe "hooking into controller dispatch" do
  include_context "app"

  before do
    @called = nil
  end

  context "request is halted" do
    let :app_def do
      local = self
      Proc.new do
        isolated :Controller do
          after :dispatch do
            local.instance_variable_set(:@called, true)
          end
        end

        controller do
          default do
            halt
          end
        end
      end
    end

    it "calls after dispatch" do
      call("/")
      expect(@called).to be(true)
    end
  end

  context "request errors" do
    let :app_def do
      local = self
      Proc.new do
        isolated :Controller do
          after :dispatch do
            local.instance_variable_set(:@called, true)
          end
        end

        controller do
          default do
            fail
          end
        end
      end
    end

    let :allow_request_failures do
      true
    end

    it "does not call after dispatch" do
      call("/")
      expect(@called).to be(nil)
    end
  end
end
