require "pakyow/plugin"

RSpec.describe "rendering view templates" do
  before do
    class TestPlugin < Pakyow::Plugin(:testable, File.join(__dir__, "support/plugin"))
    end
  end

  include_context "app"

  shared_examples :plugin_rendering do
    context "endpoint is unavailable for the request, but a template matches" do
      it "renders the view template" do
        call(File.join(plugin_mount_path, "test-plugin/render")).tap do |result|
          expect(result[0]).to eq(200)
          response_body = result[2]
          expect(response_body).to include_sans_whitespace(
            <<~HTML
              <title>app default</title>
            HTML
          )

          expect(response_body).to include_sans_whitespace(
            <<~HTML
              plugin render
            HTML
          )
        end
      end
    end

    context "endpoint renders" do
      it "renders the view template" do
        call(File.join(plugin_mount_path, "test-plugin/render/explicit")).tap do |result|
          expect(result[0]).to eq(200)
          response_body = result[2]
          expect(response_body).to include_sans_whitespace(
            <<~HTML
              <title>app default</title>
            HTML
          )

          expect(response_body).to include_sans_whitespace(
            <<~HTML
              plugin render
            HTML
          )
        end
      end
    end

    context "endpoint does not explicitly render, but a template matches" do
      it "renders the view template" do
        call(File.join(plugin_mount_path, "test-plugin/render/implicit")).tap do |result|
          expect(result[0]).to eq(200)
          response_body = result[2]
          expect(response_body).to include_sans_whitespace(
            <<~HTML
              <title>app default</title>
            HTML
          )

          expect(response_body).to include_sans_whitespace(
            <<~HTML
              plugin implicit render
            HTML
          )
        end
      end
    end

    context "app overrides the view template" do
      it "renders the app view template" do
        call(File.join(plugin_mount_path, "test-plugin/render/app-override")).tap do |result|
          expect(result[0]).to eq(200)
          response_body = result[2]
          expect(response_body).to include_sans_whitespace(
            <<~HTML
              <title>app default</title>
            HTML
          )

          expect(response_body).to include_sans_whitespace(
            <<~HTML
              app render
            HTML
          )
        end
      end

      context "app view template includes partials from the app" do
        it "renders properly" do
          call(File.join(plugin_mount_path, "test-plugin/render/app-override-with-partials")).tap do |result|
            expect(result[0]).to eq(200)
            response_body = result[2]
            expect(response_body).to include_sans_whitespace(
              <<~HTML
                <title>app default</title>
              HTML
            )

            expect(response_body).to include_sans_whitespace(
              <<~HTML
                app render
              HTML
            )

            expect(response_body).to include_sans_whitespace(
              <<~HTML
                app partial
              HTML
            )
          end
        end
      end

      context "app view template includes global partials from the app" do
        it "renders properly" do
          call(File.join(plugin_mount_path, "test-plugin/render/app-override-with-global-partials")).tap do |result|
            expect(result[0]).to eq(200)
            response_body = result[2]
            expect(response_body).to include_sans_whitespace(
              <<~HTML
                <title>app default</title>
              HTML
            )

            expect(response_body).to include_sans_whitespace(
              <<~HTML
                app render
              HTML
            )

            expect(response_body).to include_sans_whitespace(
              <<~HTML
                app global partial
              HTML
            )
          end
        end
      end

      context "app view template includes the plugin view" do
        it "renders properly" do
          call(File.join(plugin_mount_path, "test-plugin/render/app-include-plugin-view")).tap do |result|
            expect(result[0]).to eq(200)
            response_body = result[2]
            expect(response_body).to include_sans_whitespace(
              <<~HTML
                <title>app default</title>
              HTML
            )

            expect(response_body).to include_sans_whitespace(
              <<~HTML
                app render
              HTML
            )

            expect(response_body).to include_sans_whitespace(
              <<~HTML
                plugin render
              HTML
            )
          end
        end

        context "both templates include partials" do
          it "renders properly" do
            call(File.join(plugin_mount_path, "test-plugin/render/app-include-plugin-view-with-partials")).tap do |result|
              expect(result[0]).to eq(200)
              response_body = result[2]
              expect(response_body).to include_sans_whitespace(
                <<~HTML
                  <title>app default</title>
                HTML
              )

              expect(response_body).to include_sans_whitespace(
                <<~HTML
                  app render
                HTML
              )

              expect(response_body).to include_sans_whitespace(
                <<~HTML
                  app partial
                HTML
              )

              expect(response_body).to include_sans_whitespace(
                <<~HTML
                  app global partial
                HTML
              )

              expect(response_body).to include_sans_whitespace(
                <<~HTML
                  plugin render
                HTML
              )

              expect(response_body).to include_sans_whitespace(
                <<~HTML
                  plugin other_partial
                HTML
              )

              expect(response_body).to include_sans_whitespace(
                <<~HTML
                  plugin global other_partial
                HTML
              )
            end
          end
        end
      end

      context "app view template defines a component" do
        let :app_def do
          parent_app_def = super()

          Proc.new do
            class_eval(&parent_app_def)

            component :test do
              def perform
                expose :ancestors, app.class.ancestors
              end

              presenter do
                render node: -> { self } do
                  self.html = "app component render (ancestors: #{ancestors})"
                end
              end
            end
          end
        end

        it "renders with the app component, calling the component in context of the app" do
          call(File.join(plugin_mount_path, "test-plugin/render/app-override-with-component")).tap do |result|
            expect(result[0]).to eq(200)
            response_body = result[2]
            expect(response_body).to include_sans_whitespace(
              <<~HTML
                <title>app default</title>
              HTML
            )

            expect(response_body).to include_sans_whitespace(
              <<~HTML
                app render
              HTML
            )

            expect(response_body).to include_sans_whitespace(
              <<~HTML
                app component render
              HTML
            )

            expect(response_body).to include_sans_whitespace(
              <<~HTML
                Pakyow::Application
              HTML
            )
          end
        end
      end
    end

    context "plugin renders with a layout missing from the app" do
      it "renders with the plugin layout" do
        call(File.join(plugin_mount_path, "test-plugin/render/plugin-layout")).tap do |result|
          expect(result[0]).to eq(200)
          response_body = result[2]
          expect(response_body).to include_sans_whitespace(
            <<~HTML
              <title>plugin special</title>
            HTML
          )

          expect(response_body).to include_sans_whitespace(
            <<~HTML
              plugin render
            HTML
          )
        end
      end

      context "app overrides the view template" do
        it "renders the app view template in the app layout" do
          call(File.join(plugin_mount_path, "test-plugin/render/app-override-plugin-layout")).tap do |result|
            expect(result[0]).to eq(200)
            response_body = result[2]
            expect(response_body).to include_sans_whitespace(
              <<~HTML
                <title>app default</title>
              HTML
            )

            expect(response_body).to include_sans_whitespace(
              <<~HTML
                app render
              HTML
            )
          end
        end
      end
    end

    context "plugin renders with a component" do
      it "renders properly, calling the component in context of the plugin" do
        call(File.join(plugin_mount_path, "test-plugin/render/component")).tap do |result|
          expect(result[0]).to eq(200)
          response_body = result[2]
          expect(response_body).to include_sans_whitespace(
            <<~HTML
              <title>app default</title>
            HTML
          )

          expect(response_body).to include_sans_whitespace(
            <<~HTML
              plugin render
            HTML
          )

          expect(response_body).to include_sans_whitespace(
            <<~HTML
              plugin component render
            HTML
          )

          expect(response_body).to include_sans_whitespace(
            <<~HTML
              Pakyow::Plugin
            HTML
          )
        end
      end

      context "app overrides the backend component object" do
        let :app_def do
          parent_app_def = super()

          Proc.new do
            class_eval(&parent_app_def)

            component :test do
              def perform
                expose :ancestors, app.class.ancestors
              end

              presenter do
                render node: -> { self } do
                  self.html = "app component render (ancestors: #{ancestors})"
                end
              end
            end
          end
        end

        it "renders with the plugin component, calling it in context of the plugin" do
          call(File.join(plugin_mount_path, "test-plugin/render/component")).tap do |result|
            expect(result[0]).to eq(200)
            response_body = result[2]
            expect(response_body).to include_sans_whitespace(
              <<~HTML
                <title>app default</title>
              HTML
            )

            expect(response_body).to include_sans_whitespace(
              <<~HTML
                plugin render
              HTML
            )

            expect(response_body).to include_sans_whitespace(
              <<~HTML
                plugin component render
              HTML
            )

            expect(response_body).to include_sans_whitespace(
              <<~HTML
                Pakyow::Plugin
              HTML
            )
          end
        end
      end
    end
  end

  context "mounted at the root path" do
    let :app_def do
      Proc.new do
        plug :testable, at: "/"

        configure do
          config.root = File.join(__dir__, "support/app")
        end
      end
    end

    let :plugin_mount_path do
      "/"
    end

    include_examples :plugin_rendering
  end

  context "mounted at a non-root path" do
    let :app_def do
      Proc.new do
        plug :testable, at: "/foo"

        configure do
          config.root = File.join(__dir__, "support/app")
        end
      end
    end

    let :plugin_mount_path do
      "/foo"
    end

    include_examples :plugin_rendering
  end
end
