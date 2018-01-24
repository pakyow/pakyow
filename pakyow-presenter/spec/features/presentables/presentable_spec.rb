RSpec.describe "using presentables" do
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

  context "presentable is defined inline with the route" do
    context "presentable is a method" do
      let :app_definition do
        Proc.new do
          instance_exec(&$presenter_app_boilerplate)

          controller :default do
            def current_user
              "current_user"
            end

            get "/" do
              expose :current_user
            end
          end

          presenter "/" do
            $presentable = current_user
          end
        end
      end

      it "is accessible" do
        expect($presentable).to eq("current_user")
      end
    end

    context "presentable is a value" do
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

      it "is accessible" do
        expect($presentable).to eq("current_user")
      end
    end

    context "presentable is a block" do
      context "block has a default value and returns nil" do
        let :app_definition do
          Proc.new do
            instance_exec(&$presenter_app_boilerplate)

            controller :default do
              get "/" do
                expose :current_user, "default_user" do
                  nil
                end
              end
            end

            presenter "/" do
              $presentable = current_user
            end
          end
        end

        it "is the default value" do
          expect($presentable).to eq("default_user")
        end
      end

      context "block has a default value and does not return nil" do
        let :app_definition do
          Proc.new do
            instance_exec(&$presenter_app_boilerplate)

            controller :default do
              get "/" do
                expose :current_user, "default_user" do
                  "current_user"
                end
              end
            end

            presenter "/" do
              $presentable = current_user
            end
          end
        end

        it "is the value from the block" do
          expect($presentable).to eq("current_user")
        end
      end
    end
  end

  context "presentable is defined in a route, but not for the called route" do
    let :app_definition do
      Proc.new do
        instance_exec(&$presenter_app_boilerplate)

        controller :default do
          get "/" do
            expose :current_user, "current_user"
          end

          get "/other" do
          end
        end

        presenter "/" do
          $presentable = current_user
        end

        presenter "/other" do
          $presentable = respond_to?(:current_user)
        end
      end
    end

    it "sets up the test properly" do
      expect($presentable).to eq("current_user")
    end

    it "cannot access the presentable defined in the other route" do
      call "/other"
      expect($presentable).to eq(false)
    end
  end
end
