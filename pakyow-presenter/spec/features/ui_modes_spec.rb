RSpec.describe "presenting a view that defines one or more ui mode" do
  include_context "app"

  let :app_init do
    Proc.new do
      presenter "/presentation/ui_modes" do
        render :post do
          bind({})
        end
      end

      presenter "/presentation/ui_modes/default" do
        render :post do
          bind({})
        end
      end

      presenter "/presentation/ui_modes/conceal_by_type_and_name" do
        render :post do
          bind({})
        end
      end

      presenter "/presentation/ui_modes/conceal_by_type_name_and_version" do
        render :post do
          bind({})
        end
      end

      presenter "/presentation/ui_modes/display_by_type_name_and_version" do
        render :post do
          bind({})
        end
      end
    end
  end

  it "presents normally" do
    result = call("/presentation/ui_modes")[2]

    expect(result).to include_sans_whitespace(
      <<~HTML
        <h1>default</h1>
      HTML
    )

    expect(result).not_to include_sans_whitespace(
      <<~HTML
        <h1>one</h1>
      HTML
    )

    expect(result).not_to include_sans_whitespace(
      <<~HTML
        <h1>two</h1>
      HTML
    )
  end

  context "view defines a default mode" do
    it "uses the default" do
      result = call("/presentation/ui_modes/default")[2]

      expect(result).not_to include_sans_whitespace(
        <<~HTML
          <h1>default</h1>
        HTML
      )

      expect(result).not_to include_sans_whitespace(
        <<~HTML
          <h1>one</h1>
        HTML
      )

      expect(result).to include_sans_whitespace(
        <<~HTML
          <h1>two</h1>
        HTML
      )
    end
  end

  context "call to render sets the mode" do
    let :app_init do
      Proc.new do
        controller do
          default do
            render "/presentation/ui_modes", modes: [:two]
          end
        end

        presenter "/presentation/ui_modes" do
          render :post do
            bind({})
          end
        end
      end
    end

    it "uses the mode" do
      result = call("/")[2]

      expect(result).not_to include_sans_whitespace(
        <<~HTML
          <h1>default</h1>
        HTML
      )

      expect(result).not_to include_sans_whitespace(
        <<~HTML
          <h1>one</h1>
        HTML
      )

      expect(result).to include_sans_whitespace(
        <<~HTML
          <h1>two</h1>
        HTML
      )
    end
  end

  context "view defines modes not on bindings" do
    it "presents only the default nodes by default" do
      result = call("/presentation/ui_modes/non-binding")[2]

      expect(result).to include_sans_whitespace(
        <<~HTML
          <h1>default</h1>
        HTML
      )

      expect(result).not_to include_sans_whitespace(
        <<~HTML
          <h1>one</h1>
        HTML
      )

      expect(result).not_to include_sans_whitespace(
        <<~HTML
          <h1>two</h1>
        HTML
      )
    end

    context "mode is specified" do
      let :app_init do
        Proc.new do
          controller do
            default do
              render "/presentation/ui_modes/non-binding", modes: [:one]
            end
          end
        end
      end

      it "presents only nodes for the specified mode" do
        result = call("/")[2]

        expect(result).not_to include_sans_whitespace(
          <<~HTML
            <h1>default</h1>
          HTML
        )

        expect(result).to include_sans_whitespace(
          <<~HTML
            <h1>one</h1>
          HTML
        )

        expect(result).not_to include_sans_whitespace(
          <<~HTML
            <h1>two</h1>
          HTML
        )
      end
    end
  end

  context "global mode is defined" do
    let :app_def do
      Proc.new do
        mode :"signed-in" do |connection|
          connection.params.include?(:user)
        end

        mode :"signed-out" do |connection|
          !connection.params.include?(:user)
        end
      end
    end

    context "global mode is applicable" do
      it "places the view in the mode" do
        expect(call("/modes/global")[2]).to include_sans_whitespace(
          <<~HTML
            <div>
              not signed in
            </div>
          HTML
        )

        expect(call("/modes/global")[2]).not_to include_sans_whitespace(
          <<~HTML
            <div>
              signed in!
            </div>
          HTML
        )
      end
    end

    context "global mode is not applicable" do
      it "does not place the view in the mode" do
        expect(call("/modes/global?user=true")[2]).to include_sans_whitespace(
          <<~HTML
            <div>
              signed in!
            </div>
          HTML
        )

        expect(call("/modes/global?user=true")[2]).not_to include_sans_whitespace(
          <<~HTML
            <div>
              not signed in
            </div>
          HTML
        )
      end
    end
  end

  context "mode is nested in a binding" do
    let :app_init do
      Proc.new do
        presenter "/presentation/ui_modes/nested" do
          render :post do
            bind({})
          end
        end
      end
    end

    it "still gets picked up as a mode" do
      expect(call("/presentation/ui_modes/nested")[2]).to include_sans_whitespace(
        <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <title>default</title>
            </head>

            <body>
              <div data-b="post">
                <h1>default</h1>
              </div>

              <div data-b="post"></div>
              <div data-b="post"></div>
            </body>
          </html>
        HTML
      )
    end
  end

  context "mode is nested in a binding scope" do
    it "is removed from the template" do
      expect(call("/presentation/ui_modes/nested-scope")[2]).to include_sans_whitespace(
        <<~HTML
          <script type="text/template" data-b="post">
            <div data-b="post">
              <h1 data-b="title">default</h1>
            </div>
          </script>
        HTML
      )
    end
  end
end
