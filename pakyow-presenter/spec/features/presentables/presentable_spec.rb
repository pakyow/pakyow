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
        $presentable = current_user
      end
    end
  end

  it "makes exposures presentable" do
    expect($presentable).to eq("current_user")
  end
end
