RSpec.describe Pakyow::Actions::Normalizer do
  let :action do
    Pakyow::Actions::Normalizer.new
  end

  let :connection do
    Pakyow::Connection.new(request).tap do |connection|
      allow(connection).to receive(:path).and_return(path)
      allow(connection).to receive(:host).and_return(host)
      allow(connection).to receive(:port).and_return(port)
      allow(connection).to receive(:authority).and_return("#{host}:#{port}")
    end
  end

  let :request do
    instance_double(
      Async::HTTP::Protocol::Request,
      path: "#{path}#{query}"
    )
  end

  let :path do
    ""
  end

  let :query do
    ""
  end

  let :host do
    ""
  end

  let :port do
    "80"
  end

  before do
    allow(Pakyow).to receive(:global_logger).and_return(
      double(:global_logger, level: 2, verbose!: nil)
    )
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
          catch :halt do
            action.call(connection)
          end

          expect(connection.status).to eq(301)
          expect(connection.header("Location")).to eq("/foo")
        end

        context "request uri has a query string" do
          let :query do
            "?foo=bar"
          end

          it "includes the query string in the normalized path" do
            catch :halt do
              action.call(connection)
            end

            expect(connection.status).to eq(301)
            expect(connection.header("Location")).to eq("/foo/?foo=bar")
          end
        end
      end

      context "path has a double trailing slash" do
        let :path do
          "/foo//"
        end

        it "redirects to the normalized path" do
          catch :halt do
            action.call(connection)
          end

          expect(connection.status).to eq(301)
          expect(connection.header("Location")).to eq("/foo")
        end

        context "request uri has a query string" do
          let :query do
            "?foo=bar"
          end

          it "includes the query string in the normalized path" do
            catch :halt do
              action.call(connection)
            end

            expect(connection.status).to eq(301)
            expect(connection.header("Location")).to eq("/foo/?foo=bar")
          end
        end
      end

      context "path does not have a trailing slash" do
        let :path do
          "/foo"
        end

        it "does not redirect" do
          catch :halt do
            action.call(connection)
          end

          expect(connection.status).to eq(200)
          expect(connection.header?("Location")).to be(false)
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
          catch :halt do
            action.call(connection)
          end

          expect(connection.status).to eq(200)
          expect(connection.header?("Location")).to be(false)
        end
      end

      context "path does not have a trailing slash" do
        let :path do
          "/foo"
        end

        it "does not redirect" do
          catch :halt do
            action.call(connection)
          end

          expect(connection.status).to eq(200)
          expect(connection.header?("Location")).to be(false)
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
            catch :halt do
              action.call(connection)
            end

            expect(connection.status).to eq(301)
            expect(connection.header("Location")).to eq("www.pakyow.org:80/")
          end

          context "request uri has a query string" do
            let :query do
              "?foo=bar"
            end

            it "includes the query string in the normalized path" do
              catch :halt do
                action.call(connection)
              end

              expect(connection.status).to eq(301)
              expect(connection.header("Location")).to eq("www.pakyow.org:80/?foo=bar")
            end
          end
        end

        context "request uri has www" do
          let :host do
            "www.pakyow.org"
          end

          it "does not redirect" do
            catch :halt do
              action.call(connection)
            end

            expect(connection.status).to eq(200)
            expect(connection.header?("Location")).to be(false)
          end
        end

        context "request uri is a subdomain" do
          let :host do
            "foo.pakyow.org"
          end

          it "does not redirect" do
            catch :halt do
              action.call(connection)
            end

            expect(connection.status).to eq(200)
            expect(connection.header?("Location")).to be(false)
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
            catch :halt do
              action.call(connection)
            end

            expect(connection.status).to eq(301)
            expect(connection.header("Location")).to eq("pakyow.org:80/")
          end

          context "request uri has a query string" do
            let :query do
              "?foo=bar"
            end

            it "includes the query string in the normalized path" do
              catch :halt do
                action.call(connection)
              end

              expect(connection.status).to eq(301)
              expect(connection.header("Location")).to eq("pakyow.org:80/?foo=bar")
            end
          end
        end

        context "request uri does not have www" do
          it "does not redirect" do
            catch :halt do
              action.call(connection)
            end

            expect(connection.status).to eq(200)
            expect(connection.header?("Location")).to be(false)
          end
        end

        context "request uri is a subdomain" do
          it "does not redirect" do
            catch :halt do
              action.call(connection)
            end

            expect(connection.status).to eq(200)
            expect(connection.header?("Location")).to be(false)
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
            catch :halt do
              action.call(connection)
            end

            expect(connection.status).to eq(200)
            expect(connection.header?("Location")).to be(false)
          end
        end

        context "request uri has www" do
          let :host do
            "www.pakyow.org"
          end

          it "does not redirect" do
            catch :halt do
              action.call(connection)
            end

            expect(connection.status).to eq(200)
            expect(connection.header?("Location")).to be(false)
          end
        end

        context "request uri is a subdomain" do
          let :host do
            "foo.pakyow.org"
          end

          it "does not redirect" do
            catch :halt do
              action.call(connection)
            end

            expect(connection.status).to eq(200)
            expect(connection.header?("Location")).to be(false)
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
            catch :halt do
              action.call(connection)
            end

            expect(connection.status).to eq(200)
            expect(connection.header?("Location")).to be(false)
          end
        end

        context "request uri does not have www" do
          it "does not redirect" do
            catch :halt do
              action.call(connection)
            end

            expect(connection.status).to eq(200)
            expect(connection.header?("Location")).to be(false)
          end
        end

        context "request uri is a subdomain" do
          it "does not redirect" do
            catch :halt do
              action.call(connection)
            end

            expect(connection.status).to eq(200)
            expect(connection.header?("Location")).to be(false)
          end
        end
      end
    end
  end
end
