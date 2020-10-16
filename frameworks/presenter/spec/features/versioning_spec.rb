RSpec.describe "view versioning via presenter" do
  include_context "app"

  context "when a version is unspecified" do
    context "when there is one unversioned view" do
      let :app_def do
        Proc.new do
          presenter "/presentation/versioning/single" do
            render :post do
              present(title: "foo")
            end
          end
        end
      end

      it "renders it" do
        expect(call("/presentation/versioning/single")[2]).to include_sans_whitespace(
          <<~HTML
            <div data-b="post">
              <h1 data-b="title">foo</h1>
            </div>
          HTML
        )
      end
    end

    context "when there are multiple views, one of them being versioned" do
      let :app_def do
        Proc.new do
          presenter "/presentation/versioning/multiple-one-versioned" do
            render :post do
              present(title: "foo")
            end
          end
        end
      end

      it "renders the first one" do
        expect(call("/presentation/versioning/multiple-one-versioned")[2]).to include_sans_whitespace(
          <<~HTML
            <div data-b="post">
              <h1 data-b="title">foo</h1>
            </div>
          HTML
        )
      end
    end

    context "when there is only a default version" do
      let :app_def do
        Proc.new do
          presenter "/presentation/versioning/default" do
            render :post do
              present(title: "foo")
            end
          end
        end
      end

      it "renders the default" do
        expect(call("/presentation/versioning/default")[2]).to include_sans_whitespace(
          <<~HTML
            <div data-b="post" data-v="default">
              <h1 data-b="title">foo</h1>
            </div>
          HTML
        )
      end
    end

    context "when there are multiple versions, including a default" do
      let :app_def do
        Proc.new do
          presenter "/presentation/versioning/multiple-with-default" do
            render :post do
              present(title: "foo")
            end
          end
        end
      end

      it "renders the default" do
        expect(call("/presentation/versioning/multiple-with-default")[2]).to include_sans_whitespace(
          <<~HTML
            <div data-b="post" data-v="default">
              <h1 data-b="title">foo</h1>
            </div>
          HTML
        )
      end
    end

    context "when there are multiple versions, without a default" do
      let :app_def do
        Proc.new do
          presenter "/presentation/versioning/multiple-without-default" do
            render :post do
              present(title: "foo")
            end
          end
        end
      end

      it "renders the first one" do
        expect(call("/presentation/versioning/multiple-without-default")[2]).to include_sans_whitespace(
          <<~HTML
            <div data-b="post" data-v="one">
              <h1 data-b="title">foo</h1>
            </div>
          HTML
        )
      end
    end

    context "when there are multiple versioned props, including a default" do
      let :app_def do
        Proc.new do
          presenter "/presentation/versioning/props/multiple-with-default" do
            render :post do
              present(title: "foo")
            end
          end
        end
      end

      it "renders the default" do
        expect(call("/presentation/versioning/props/multiple-with-default")[2]).to include_sans_whitespace(
          <<~HTML
            <div data-b="post">
              <h1 data-b="title" data-v="default">foo</h1>
            </div>
          HTML
        )
      end

      context "view is presented" do
        let :mode do
          :development
        end

        let :app_def do
          Proc.new do
            presenter "/presentation/versioning/props/multiple-with-default" do
              render do
                find(:post).present([{ title: "one" }])
              end
            end
          end
        end

        it "renders only the default" do
          expect(call("/presentation/versioning/props/multiple-with-default")[2]).to include_sans_whitespace(
            <<~HTML
              <div data-b="post">
                <h1 data-b="title" data-v="default">one</h1>
              </div>
            HTML
          )
        end
      end
    end
  end

  context "when a version is used" do
    let :mode do
      :test
    end

    let :app_def do
      Proc.new do
        presenter "/presentation/versioning/multiple-without-default" do
          render :post do
            use(:two).bind(title: "used two")
          end
        end
      end
    end

    it "only renders the used version" do
      expect(call("/presentation/versioning/multiple-without-default")[2]).to eq_sans_whitespace(
        <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <title>default</title>
            </head>

            <body>
              <div data-b="post" data-v="two">
                <h1 data-b="title">used two</h1>
              </div>

              <script type="text/template" data-b="post" data-v="one">
                <div data-b="post" data-v="one">
                  <h1 data-b="title">one</h1>
                </div>
              </script>

              <script type="text/template" data-b="post" data-v="two">
                <div data-b="post" data-v="two">
                  <h1 data-b="title">two</h1>
                </div>
              </script>
            </body>
          </html>
        HTML
      )
    end

    context "when the used version is missing" do
      let :app_def do
        Proc.new do
          presenter "/presentation/versioning/multiple-without-default" do
            render :post do
              use(:three)
            end
          end
        end
      end

      it "does not render a version" do
        expect(call("/presentation/versioning/multiple-without-default")[2]).to eq_sans_whitespace(
          <<~HTML
            <!DOCTYPE html>
            <html>
              <head>
                <title>default</title>
              </head>

              <body>
                <script type="text/template" data-b="post" data-v="one">
                  <div data-b="post" data-v="one">
                    <h1 data-b="title">one</h1>
                  </div>
                </script>

                <script type="text/template" data-b="post" data-v="two">
                  <div data-b="post" data-v="two">
                    <h1 data-b="title">two</h1>
                  </div>
                </script>
              </body>
            </html>
          HTML
        )
      end
    end
  end

  context "when using versioned props inside of an unversioned scope" do
    let :mode do
      :test
    end

    let :app_def do
      Proc.new do
        presenter "/presentation/versioning/versioned-props-unversioned-scope" do
          render :post do
            find(:title).use(:two).object.set_label(:bound, true)
            view.object.set_label(:bound, true)
          end
        end
      end
    end

    it "renders appropriately" do
      expect(call("/presentation/versioning/versioned-props-unversioned-scope")[2]).to eq_sans_whitespace(
        <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <title>default</title>
            </head>

            <body>
              <div data-b="post">
                <h1 data-b="title" data-v="two">two</h1>
              </div>

              <script type="text/template" data-b="post">
                <div data-b="post">
                  <h1 data-b="title" data-v="default">default</h1>
                  <h1 data-b="title" data-v="two">two</h1>
                </div>
              </script>
            </body>
          </html>
        HTML
      )
    end
  end

  context "when using versioned props inside of a versioned scope" do
    let :mode do
      :test
    end

    let :app_def do
      Proc.new do
        presenter "/presentation/versioning/versioned-props-versioned-scope" do
          render :post do
            use(:two).find(:title).use(:two).object.set_label(:bound, true)
            view.object.set_label(:bound, true)
          end
        end
      end
    end

    it "renders appropriately" do
      expect(call("/presentation/versioning/versioned-props-versioned-scope")[2]).to eq_sans_whitespace(
        <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <title>default</title>
            </head>

            <body>
              <div data-b="post" data-v="two">
                <h1 data-b="title" data-v="two">two</h1>
              </div>

              <script type="text/template" data-b="post" data-v="one">
                <div data-b="post" data-v="one">
                  <h1 data-b="title">one</h1>
                </div>
              </script>

              <script type="text/template" data-b="post" data-v="two">
                <div data-b="post" data-v="two">
                  <h1 data-b="title" data-v="one">one</h1>
                  <h1 data-b="title" data-v="two">two</h1>
                </div>
              </script>
            </body>
          </html>
        HTML
      )
    end
  end

  describe "finding a version" do
    let :mode do
      :test
    end

    let :app_def do
      local = self
      Proc.new do
        presenter "/presentation/versioning/multiple-without-default" do
          render :post do
            local.instance_variable_set(:@versioned, versioned(:two))
          end
        end
      end
    end

    it "returns the view matching the version" do
      call("/presentation/versioning/multiple-without-default")
      expect(@versioned.class.ancestors).to include(Test::Presenter)
      expect(@versioned.version).to eq(:two)
    end

    context "match is not found" do
      let :app_def do
        local = self
        Proc.new do
          presenter "/presentation/versioning/multiple-without-default" do
            render :post do
              local.instance_variable_set(:@versioned, versioned(:nonexistent))
            end
          end
        end
      end

      it "returns nil" do
        call("/presentation/versioning/multiple-without-default")
        expect(@versioned).to be(nil)
      end
    end
  end

  describe "presenting a versioned view" do
    let :mode do
      :test
    end

    let :app_def do
      Proc.new do
        presenter "/presentation/versioning/multiple-with-default" do
          render :post do
            present([{ title: "default" }, { title: "three" }, { title: "two" }])
          end
        end
      end
    end

    it "presents the default version" do
      expect(call("/presentation/versioning/multiple-with-default")[2]).to eq_sans_whitespace(
        <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <title>default</title>
            </head>

            <body>
              <div data-b="post" data-v="default">
                <h1 data-b="title">default</h1>
              </div>

              <div data-b="post" data-v="default">
                <h1 data-b="title">three</h1>
              </div>

              <div data-b="post" data-v="default">
                <h1 data-b="title">two</h1>
              </div>

              <script type="text/template" data-b="post" data-v="one">
                <div data-b="post" data-v="one">
                  <h1 data-b="title">one</h1>
                </div>
              </script>

              <script type="text/template" data-b="post" data-v="default">
                <div data-b="post" data-v="default">
                  <h1 data-b="title">default</h1>
                </div>
              </script>
            </body>
          </html>
        HTML
      )
    end

    context "using versions during presentation" do
      let :app_def do
        Proc.new do
          presenter "/presentation/versioning/presented" do
            render :post do
              present([{ title: "default" }, { title: "three" }, { title: "two" }]) do |view, object|
                view.use(object[:title])
              end
            end
          end
        end
      end

      it "uses a version for each object" do
        expect(call("/presentation/versioning/presented")[2]).to eq_sans_whitespace(
          <<~HTML
            <!DOCTYPE html>
            <html>
              <head>
                <title>default</title>
              </head>

              <body>
                <div data-b="post" data-v="default" title="default">
                  <h1 data-b="title">default</h1>
                </div>

                <div data-b="post" data-v="three" title="three">
                  <h1 data-b="title">three</h1>
                </div>

                <div data-b="post" data-v="two" title="two">
                  <h1 data-b="title">two</h1>
                </div>

                <script type="text/template" data-b="post" data-v="default">
                  <div data-b="post" data-v="default" title="default">
                    <h1 data-b="title">default</h1>
                  </div>
                </script>

                <script type="text/template" data-b="post" data-v="two">
                  <div data-b="post" data-v="two" title="two">
                    <h1 data-b="title">two</h1>
                  </div>
                </script>

                <script type="text/template" data-b="post" data-v="three">
                  <div data-b="post" data-v="three" title="three">
                    <h1 data-b="title">three</h1>
                  </div>
                </script>
              </body>
            </html>
          HTML
        )
      end
    end

    context "data is empty" do
      context "empty version exists" do
        let :app_def do
          Proc.new do
            presenter "/presentation/versioning/empty" do
              render :post do
                present([])
              end
            end
          end
        end

        it "renders the empty version" do
          expect(call("/presentation/versioning/empty")[2]).to eq_sans_whitespace(
            <<~HTML
              <!DOCTYPE html>
              <html>
                <head>
                  <title>default</title>
                </head>

                <body>
                  <div data-b="post" data-v="empty">
                    no posts here
                  </div>

                  <script type="text/template" data-b="post" data-v="empty">
                    <div data-b="post" data-v="empty">
                      no posts here
                    </div>
                  </script>

                  <script type="text/template" data-b="post">
                    <div data-b="post">
                      <h1 data-b="title">post title</h1>
                    </div>
                  </script>
                </body>
              </html>
            HTML
          )
        end
      end

      context "empty version exists after the binding" do
        let :app_def do
          Proc.new do
            presenter "/presentation/versioning/empty-last" do
              render :post do
                present([])
              end
            end
          end
        end

        it "renders the empty version" do
          expect(call("/presentation/versioning/empty-last")[2]).to eq_sans_whitespace(
            <<~HTML
              <!DOCTYPE html>
              <html>
                <head>
                  <title>default</title>
                </head>

                <body>
                  <div data-b="post" data-v="empty">
                    no posts here
                  </div>

                  <script type="text/template" data-b="post">
                    <div data-b="post">
                      <h1 data-b="title">post title</h1>
                    </div>
                  </script>

                  <script type="text/template" data-b="post" data-v="empty">
                    <div data-b="post" data-v="empty">
                      no posts here
                    </div>
                  </script>
                </body>
              </html>
            HTML
          )
        end
      end

      context "empty version does not exist" do
        let :app_def do
          Proc.new do
            presenter "/presentation/versioning/sans-empty" do
              render :post do
                present([])
              end
            end
          end
        end

        it "renders nothing" do
          expect(call("/presentation/versioning/sans-empty")[2]).to eq_sans_whitespace(
            <<~HTML
              <!DOCTYPE html>
              <html>
                <head>
                  <title>default</title>
                </head>

                <body>
                  <script type="text/template" data-b="post">
                    <div data-b="post">
                      <h1 data-b="title">post title</h1>
                    </div>
                  </script>
                </body>
              </html>
            HTML
          )
        end
      end
    end
  end
end
