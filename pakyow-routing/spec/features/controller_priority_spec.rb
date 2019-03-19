RSpec.describe "controller priority" do
  include_context "app"

  context "when no priority is set" do
    let :app_init do
      Proc.new {
        controller do
          default do
            send "one"
          end
        end

        controller do
          default do
            send "two"
          end
        end
      }
    end

    it "prioritizes controllers as first in, first out" do
      expect(call[2]).to eq("one")
    end
  end

  context "when a controller is defined as high priority" do
    let :app_init do
      Proc.new {
        controller do
          default do
            send "one"
          end
        end

        controller priority: :high do
          default do
            send "two"
          end
        end
      }
    end

    it "is prioritized above the others" do
      expect(call[2]).to eq("two")
    end
  end

  context "when a controller is defined as low priority" do
    let :app_init do
      Proc.new {
        controller priority: :low do
          default do
            send "one"
          end
        end

        controller do
          default do
            send "two"
          end
        end
      }
    end

    it "is prioritized below the others" do
      expect(call[2]).to eq("two")
    end
  end

  context "when a controller is defined with a custom priority" do
    let :app_init do
      Proc.new {
        controller priority: :high do
          default do
            send "one"
          end
        end

        controller priority: 100 do
          default do
            send "two"
          end
        end
      }
    end

    it "is prioritized related to the others" do
      expect(call[2]).to eq("two")
    end
  end
end
