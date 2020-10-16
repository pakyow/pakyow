RSpec.describe "halting a request" do
  include_context "app"

  context "when halting from a route" do
    let :app_def do
      Proc.new {
        controller do
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

  context "when halting from a pipeline action" do
    let :app_def do
      Proc.new {
        controller do
          action :hook

          def hook
            $hooked = true
            halt
          end

          default do
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

  context "when halting with a body" do
    let :app_def do
      Proc.new {
        controller do
          default do
            halt StringIO.new("foo")
          end
        end
      }
    end

    it "sets the response body, halts, and returns the response" do
      expect(call[2]).to eq("foo")
    end
  end

  context "halting with a status code" do
    let :app_def do
      Proc.new {
        controller do
          default do
            halt status: 417
          end
        end
      }
    end

    it "sets the status code on the response, halts, and returns the response" do
      expect(call[0]).to eq(417)
    end
  end

  context "halting with a nice status code" do
    let :app_def do
      Proc.new {
        controller do
          default do
            halt status: :bad_request
          end
        end
      }
    end

    it "sets the status code on the response, halts, and returns the response" do
      expect(call[0]).to eq(400)
    end
  end
end
