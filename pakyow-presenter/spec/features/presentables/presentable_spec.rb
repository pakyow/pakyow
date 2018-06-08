RSpec.describe "presentable exposures" do
  include_context "testable app"

  before do
    call "/"
  end

  after do
    $presentable = nil
  end

  let :app_definition do
    Proc.new do
      instance_exec(&$presenter_app_boilerplate)

      controller :default do
        get "/" do
          expose :current_user, "current_user"
        end
      end

      presenter "/" do
        perform do
          $presentable = current_user
        end
      end
    end
  end

  it "makes exposures presentable" do
    expect($presentable).to eq("current_user")
  end

  context "multiple exposures are made, but for different channels" do
    after do
      $presentables = nil
    end

    let :app_definition do
      Proc.new do
        instance_exec(&$presenter_app_boilerplate)

        controller :default do
          get "/" do
            expose :current_user, "user1", channel: [:foo]
            expose :current_user, "user2", channel: [:foo, :bar]
          end
        end

        presenter "/" do
          perform do
            $presentables = {
              default: current_user,
              foo: current_user(:foo),
              foo_bar: current_user(:foo, :bar)
            }
          end
        end
      end
    end

    it "returns none of the channeled values when no channel is provided" do
      expect($presentables[:default]).to be(nil)
    end

    it "makes each exposure available by its channel" do
      expect($presentables[:foo]).to eq("user1")
      expect($presentables[:foo_bar]).to eq("user2")
    end
  end
end
