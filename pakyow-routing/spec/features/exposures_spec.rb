RSpec.describe "exposures" do
  include_context "app"

  before do
    call "/"
  end

  after do
    $connection = nil
  end

  context "exposure is defined inline with the route" do
    context "exposure is a method" do
      let :app_init do
        Proc.new do
          controller :default do
            def current_user
              "current_user"
            end

            get "/" do
              expose :current_user
              $connection = connection
            end
          end
        end
      end

      it "is accessible" do
        expect($connection.get(:current_user)).to eq("current_user")
      end
    end

    context "exposure is a value" do
      let :app_init do
        Proc.new do
          controller :default do
            get "/" do
              expose :current_user, "current_user"
              $connection = connection
            end
          end
        end
      end

      it "is accessible" do
        expect($connection.get(:current_user)).to eq("current_user")
      end
    end

    context "exposure is a block" do
      context "block has a default value and returns nil" do
        let :app_init do
          Proc.new do
            controller :default do
              get "/" do
                expose :current_user, "default_user" do
                  nil
                end

                $connection = connection
              end
            end
          end
        end

        it "is the default value" do
          expect($connection.get(:current_user)).to eq("default_user")
        end
      end

      context "block has a default value and does not return nil" do
        let :app_init do
          Proc.new do
            controller :default do
              get "/" do
                expose :current_user, "default_user" do
                  "current_user"
                end

                $connection = connection
              end
            end
          end
        end

        it "is the value from the block" do
          expect($connection.get(:current_user)).to eq("current_user")
        end
      end
    end
  end

  context "exposure is defined in a route, but not for the called route" do
    let :app_init do
      Proc.new do
        controller :default do
          get "/" do
            expose :current_user, "current_user"
            $connection = connection
          end

          get "/other" do
            $connection = connection
          end
        end
      end
    end

    it "sets up the test properly" do
      expect($connection.get(:current_user)).to eq("current_user")
    end

    it "cannot access the exposure defined in the other route" do
      call "/other"
      expect($connection.get(:current_user)).to eq(nil)
    end
  end

  context "exposure is defined with a non-symbol key" do
    let :app_init do
      Proc.new do
        controller :default do
          get "/" do
            expose "current_user", "current_user"
            $connection = connection
          end
        end
      end
    end

    it "can still be looked up using a symbol" do
      expect($connection.get(:current_user)).to eq("current_user")
    end
  end

  context "exposure is defined multiple times" do
    let :app_init do
      Proc.new do
        controller :default do
          get "/" do
            expose :current_user, "foo"
            expose :current_user, "bar"
            $connection = connection
          end
        end
      end
    end

    it "overrides the initial value" do
      expect($connection.get(:current_user)).to eq("bar")
    end
  end
end
