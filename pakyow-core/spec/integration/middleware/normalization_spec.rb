RSpec.describe "request path normalization" do
  let :app do
    double("app")
  end

  let :normalizer do
    Pakyow::Middleware::Normalizer.new(app)
  end

  let :env do
    { Rack::PATH_INFO => path, Rack::SERVER_NAME => host }
  end

  let :path do
    ""
  end

  let :host do
    ""
  end

  describe "normalizing the trailing slash" do
    context "strict path is enabled" do
      before do
        Pakyow.config.normalizer.strict_path = true
      end

      context "path has a trailing slash" do
        let :path do
          "/foo/"
        end

        it "redirects to the normalized path" do
          res = normalizer.call(env)
          expect(res[0]).to eq(301)
          expect(res[1]["Location"]).to eq("/foo")
        end
      end

      context "path has a double trailing slash" do
        let :path do
          "/foo//"
        end

        it "redirects to the normalized path" do
          res = normalizer.call(env)
          expect(res[0]).to eq(301)
          expect(res[1]["Location"]).to eq("/foo")
        end
      end

      context "path does not have a trailing slash" do
        let :path do
          "/foo"
        end

        it "does not redirect" do
          expect(app).to receive(:call)
          normalizer.call(env)
        end
      end
    end

    context "strict path is disabled" do
      before do
        Pakyow.config.normalizer.strict_path = false
      end

      context "path has a trailing slash" do
        let :path do
          "/foo/"
        end

        it "does not redirect" do
          expect(app).to receive(:call)
          normalizer.call(env)
        end
      end

      context "path does not have a trailing slash" do
        let :path do
          "/foo"
        end

        it "does not redirect" do
          expect(app).to receive(:call)
          normalizer.call(env)
        end
      end
    end
  end

  describe "normalizing www" do
    context "www is strict" do
      before do
        Pakyow.config.normalizer.strict_www = true
      end

      context "www is required" do
        before do
          Pakyow.config.normalizer.require_www = true
        end

        context "request uri does not have www" do
          let :host do
            "pakyow.org"
          end

          it "redirects to the normalized path" do
            res = normalizer.call(env)
            expect(res[0]).to eq(301)
            expect(res[1]["Location"]).to eq("www.pakyow.org/")
          end
        end

        context "request uri has www" do
          let :host do
            "www.pakyow.org"
          end

          it "does not redirect" do
            expect(app).to receive(:call)
            normalizer.call(env)
          end
        end

        context "request uri is a subdomain" do
          let :host do
            "foo.pakyow.org"
          end

          it "does not redirect" do
            expect(app).to receive(:call)
            normalizer.call(env)
          end
        end
      end

      context "www is not required" do
        before do
          Pakyow.config.normalizer.require_www = false
        end

        context "request uri has www" do
          let :host do
            "www.pakyow.org"
          end

          it "redirects to the normalized path" do
            res = normalizer.call(env)
            expect(res[0]).to eq(301)
            expect(res[1]["Location"]).to eq("pakyow.org/")
          end
        end

        context "request uri does not have www" do
          it "does not redirect" do
            expect(app).to receive(:call)
            normalizer.call(env)
          end
        end

        context "request uri is a subdomain" do
          it "does not redirect" do
            expect(app).to receive(:call)
            normalizer.call(env)
          end
        end
      end
    end

    context "www is not strict" do
      before do
        Pakyow.config.normalizer.strict_www = false
      end

      context "www is required" do
        before do
          Pakyow.config.normalizer.require_www = true
        end

        context "request uri does not have www" do
          let :host do
            "pakyow.org"
          end

          it "does not redirect" do
            expect(app).to receive(:call)
            normalizer.call(env)
          end
        end

        context "request uri has www" do
          let :host do
            "www.pakyow.org"
          end

          it "does not redirect" do
            expect(app).to receive(:call)
            normalizer.call(env)
          end
        end

        context "request uri is a subdomain" do
          let :host do
            "foo.pakyow.org"
          end

          it "does not redirect" do
            expect(app).to receive(:call)
            normalizer.call(env)
          end
        end
      end

      context "www is not required" do
        before do
          Pakyow.config.normalizer.require_www = false
        end

        context "request uri has www" do
          let :host do
            "www.pakyow.org"
          end

          it "does not redirect" do
            expect(app).to receive(:call)
            normalizer.call(env)
          end
        end

        context "request uri does not have www" do
          it "does not redirect" do
            expect(app).to receive(:call)
            normalizer.call(env)
          end
        end

        context "request uri is a subdomain" do
          it "does not redirect" do
            expect(app).to receive(:call)
            normalizer.call(env)
          end
        end
      end
    end
  end
end
