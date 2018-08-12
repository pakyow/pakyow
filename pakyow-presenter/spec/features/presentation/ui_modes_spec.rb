RSpec.describe "presenting a view that defines one or more ui mode" do
  include_context "testable app"

  let :app_definition do
    Proc.new {
      instance_exec(&$presenter_app_boilerplate)

      presenter "/presentation/ui_modes" do
        def perform
          find(:post).bind({})
        end
      end

      presenter "/presentation/ui_modes/default" do
        def perform
          find(:post).bind({})
        end
      end

      presenter "/presentation/ui_modes/conceal_by_type_and_name" do
        def perform
          find(:post).bind({})
        end
      end

      presenter "/presentation/ui_modes/conceal_by_type_name_and_version" do
        def perform
          find(:post).bind({})
        end
      end

      presenter "/presentation/ui_modes/display_by_type_name_and_version" do
        def perform
          find(:post).bind({})
        end
      end
    }
  end

  it "presents normally" do
    result = call("/presentation/ui_modes")[2].body.read

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
      result = call("/presentation/ui_modes/default")[2].body.read

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
    let :app_definition do
      Proc.new {
        instance_exec(&$presenter_app_boilerplate)

        controller do
          default do
            render "/presentation/ui_modes", mode: :two
          end
        end

        presenter "/presentation/ui_modes" do
          def perform
            find(:post).bind({})
          end
        end
      }
    end

    it "uses the mode" do
      result = call("/")[2].body.read

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
end
