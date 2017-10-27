RSpec.describe "using presentables" do
  include_context "testable app"

  before do
    call "/"
  end

  after do
    $presentable = nil
  end

  context "presentable is defined globally in the router" do
    context "presentable is a method" do
      let :app_definition do
        Proc.new do
          instance_exec(&$presenter_app_boilerplate)

          module Pakyow::Helpers
            def current_user
              "current_user"
            end
          end

          router :default do
            presentable :current_user

            get "/" do
            end
          end

          Pakyow::App.view "/" do
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

          router :default do
            presentable :current_user, "current_user"

            get "/" do
            end
          end

          Pakyow::App.view "/" do
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

            router :default do
              presentable :current_user, "default_user" do
                nil
              end

              get "/" do
              end
            end

            Pakyow::App.view "/" do
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

            router :default do
              presentable :current_user, "default_user" do
                "current_user"
              end

              get "/" do
              end
            end

            Pakyow::App.view "/" do
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

  context "presentable is defined inline with the route" do
    context "presentable is a method" do
      let :app_definition do
        Proc.new do
          instance_exec(&$presenter_app_boilerplate)

          router :default do
            get "/" do
              def current_user
                "current_user"
              end

              presentable :current_user
            end
          end

          Pakyow::App.view "/" do
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

          router :default do
            get "/" do
              presentable :current_user, "current_user"
            end
          end

          Pakyow::App.view "/" do
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

            router :default do
              get "/" do
                presentable :current_user, "default_user" do
                  nil
                end
              end
            end

            Pakyow::App.view "/" do
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

            router :default do
              get "/" do
                presentable :current_user, "default_user" do
                  "current_user"
                end
              end
            end

            Pakyow::App.view "/" do
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

        router :default do
          get "/" do
            presentable :current_user, "current_user"
          end

          get "/other" do
          end
        end

        Pakyow::App.view "/" do
          $presentable = current_user
        end

        Pakyow::App.view "/other" do
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
