RSpec.describe "accessing request context in presentables" do
  include_context "testable app"

  before do
    call "/?test=testing123"
  end

  after do
    $presentable = nil
  end

  context "presentable is defined inline with the route" do
    context "presentable is a method" do
      let :app_definition do
        Proc.new do
          instance_exec(&$presenter_app_boilerplate)

          controller :default do
            get "/" do
              def test_param
                params[:test]
              end

              presentable :test_param
            end
          end

          view "/" do
            $presentable = test_param
          end
        end
      end

      it "has access to request params" do
        expect($presentable).to eq("testing123")
      end
    end

    context "presentable is a value" do
      let :app_definition do
        Proc.new do
          instance_exec(&$presenter_app_boilerplate)

          controller :default do
            get "/" do
              presentable :test_param, params[:test]
            end
          end

          view "/" do
            $presentable = test_param
          end
        end
      end

      it "has access to request params" do
        expect($presentable).to eq("testing123")
      end
    end

    context "presentable is a block" do
      let :app_definition do
        Proc.new do
          instance_exec(&$presenter_app_boilerplate)

          controller :default do
            get "/" do
              presentable :test_param do
                params[:test]
              end
            end
          end

          view "/" do
            $presentable = test_param
          end
        end
      end

      it "is the value from the block" do
        expect($presentable).to eq("testing123")
      end
    end
  end
end
