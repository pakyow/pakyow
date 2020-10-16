RSpec.describe "presentable exposures" do
  include_context "app"

  before do
    call "/"
  end

  let :app_def do
    local = self
    Proc.new do
      controller :default do
        get "/" do
          expose :current_user, "current_user"
          render "/presentation/transforms"
        end
      end

      presenter "/presentation/transforms" do
        render :post do
          local.instance_variable_set(:@presentable, current_user)
        end
      end
    end
  end

  it "makes exposures presentable" do
    expect(@presentable).to eq("current_user")
  end

  context "multiple exposures are made, but for different channels" do
    let :app_def do
      local = self
      Proc.new do
        controller :default do
          get "/" do
            expose "current_user:foo", "user1"
            expose "current_user:foo:bar", "user2"
            render "/presentation/transforms"
          end
        end

        presenter "/presentation/transforms" do
          render :post do
            local.instance_variable_set(:@presentables, {
              default: current_user,
              foo: current_user(:foo),
              foo_bar: current_user(:foo, :bar)
            })
          end
        end
      end
    end

    it "returns none of the channeled values when no channel is provided" do
      expect(@presentables[:default]).to be(nil)
    end

    it "makes each exposure available by its channel" do
      expect(@presentables[:foo]).to eq("user1")
      expect(@presentables[:foo_bar]).to eq("user2")
    end
  end
end
