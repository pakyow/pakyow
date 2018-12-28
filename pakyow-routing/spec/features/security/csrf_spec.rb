RSpec.describe "processing requests with csrf protection" do
  include_context "app"

  context "csrf protection rejects the request" do
    before do
      allow_any_instance_of(
        Pakyow::Security::CSRF::VerifySameOrigin
      ).to receive(:allowed?).and_return(false)

      $calls = []
    end

    let :app_definition do
      Proc.new do
        controller do
          post "/" do
            $calls << "should not be called"
          end
        end
      end
    end

    it "does not call the route" do
      call("/", method: :post)
      expect($calls).to be_empty
    end

    it "returns a 403 response" do
      expect(call("/", method: :post)[0]).to be(403)
    end

    context "403 handler is defined in the controller" do
      let :app_definition do
        Proc.new do
          controller do
            handle 403 do
              send "403"
            end

            post "/" do
            end
          end
        end
      end

      it "calls the handler" do
        expect(call("/", method: :post)[2].body.read).to eq("403")
      end
    end

    context "403 handler is defined globally" do
      let :app_definition do
        Proc.new do
          handle 403 do
            send "403"
          end

          controller do
            post "/" do
            end
          end
        end
      end

      it "calls the handler" do
        expect(call("/", method: :post)[2].body.read).to eq("403")
      end
    end

    context "error handler is defined in the controller" do
      let :app_definition do
        Proc.new do
          controller do
            handle Pakyow::Security::InsecureRequest, as: 404 do
              send "404"
            end

            post "/" do
            end
          end
        end
      end

      it "calls the handler" do
        expect(call("/", method: :post)[2].body.read).to eq("404")
      end
    end

    context "error handler is defined globally" do
      let :app_definition do
        Proc.new do
          handle Pakyow::Security::InsecureRequest, as: 404 do
            send "404"
          end

          controller do
            post "/" do
            end
          end
        end
      end

      it "calls the handler" do
        expect(call("/", method: :post)[2].body.read).to eq("404")
      end
    end
  end

  describe "disabling csrf protection in a controller" do
    let :app_definition do
      Proc.new do
        controller do
          disable_protection :csrf

          post "/" do
          end
        end
      end
    end

    it "disables protection" do
      expect(call("/", method: :post)[0]).to eq(200)
    end
  end

  describe "disabling csrf protection, except for some routes" do
    let :app_definition do
      Proc.new do
        controller do
          disable_protection :csrf, except: [:foo]

          post :foo, "/foo" do
          end

          post :bar, "/bar" do
          end
        end
      end
    end

    it "disables protection for the appropriate routes" do
      expect(call("/foo", method: :post)[0]).to eq(403)
      expect(call("/bar", method: :post)[0]).to eq(200)
    end
  end

  describe "disabling csrf protection, only for some routes" do
    let :app_definition do
      Proc.new do
        controller do
          disable_protection :csrf, only: [:foo]

          post :foo, "/foo" do
          end

          post :bar, "/bar" do
          end
        end
      end
    end

    it "disables protection for the appropriate routes" do
      expect(call("/foo", method: :post)[0]).to eq(200)
      expect(call("/bar", method: :post)[0]).to eq(403)
    end
  end
end
