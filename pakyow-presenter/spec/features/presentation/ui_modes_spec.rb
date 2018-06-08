RSpec.describe "presenting a view that defines one or more ui mode" do
  include_context "testable app"

  let :app_definition do
    Proc.new {
      instance_exec(&$presenter_app_boilerplate)

      presenter "/presentation/ui_modes" do
        perform do
          find(:post).bind({})
        end
      end

      presenter "/presentation/ui_modes/default" do
        perform do
          find(:post).bind({})
        end
      end

      presenter "/presentation/ui_modes/conceal_by_type_and_name" do
        perform do
          find(:post).bind({})
        end
      end

      presenter "/presentation/ui_modes/conceal_by_type_name_and_version" do
        perform do
          find(:post).bind({})
        end
      end

      presenter "/presentation/ui_modes/display_by_type_name_and_version" do
        perform do
          find(:post).bind({})
        end
      end
    }
  end

  it "presents normally" do
    result = call("/presentation/ui_modes")[2].body.read

    expect(result).to include_sans_whitespace(
      <<~HTML
        <div data-b="post">
          <h1>default</h1>
        </div>
      HTML
    )

    expect(result).not_to include_sans_whitespace(
      <<~HTML
        <div data-b="post">
          <h1>one</h1>
        </div>
      HTML
    )

    expect(result).not_to include_sans_whitespace(
      <<~HTML
        <div data-b="post">
          <h1>two</h1>
        </div>
      HTML
    )
  end

  context "view defines a default mode" do
    it "uses the default" do
      result = call("/presentation/ui_modes/default")[2].body.read

      expect(result).not_to include_sans_whitespace(
        <<~HTML
          <div data-b="post">
            <h1>default</h1>
          </div>
        HTML
      )

      expect(result).not_to include_sans_whitespace(
        <<~HTML
          <div data-b="post">
            <h1>one</h1>
          </div>
        HTML
      )

      expect(result).to include_sans_whitespace(
        <<~HTML
          <div data-b="post" data-v="two">
            <h1>two</h1>
          </div>
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
          perform do
            find(:post).bind({})
          end
        end
      }
    end

    it "uses the mode" do
      result = call("/")[2].body.read

      expect(result).not_to include_sans_whitespace(
        <<~HTML
          <div data-b="post">
            <h1>default</h1>
          </div>
        HTML
      )

      expect(result).not_to include_sans_whitespace(
        <<~HTML
          <div data-b="post">
            <h1>one</h1>
          </div>
        HTML
      )

      expect(result).to include_sans_whitespace(
        <<~HTML
          <div data-b="post" data-v="two">
            <h1>two</h1>
          </div>
        HTML
      )
    end
  end

  context "concealing a node by type and name" do
    it "conceals the node matching type and name" do
      result = call("/presentation/ui_modes/conceal_by_type_and_name")[2].body.read

      expect(result).to include_sans_whitespace(
        <<~HTML
          <div data-b="post">
            <h1>post</h1>
          </div>
        HTML
      )

      expect(result).not_to include_sans_whitespace(
        <<~HTML
          <div data-b="comment">
            <h1>comment</h1>
          </div>
        HTML
      )
    end
  end

  context "concealing a node by type, name, and version" do
    it "conceals the node matching type, name and version" do
      result = call("/presentation/ui_modes/conceal_by_type_name_and_version")[2].body.read

      expect(result).not_to include_sans_whitespace(
        <<~HTML
          <div data-b="post">
            <h1>one</h1>
          </div>
        HTML
      )

      expect(result).to include_sans_whitespace(
        <<~HTML
          <div data-b="post" data-v="two">
            <h1>two</h1>
          </div>
        HTML
      )
    end
  end

  context "displaying a node by type, name, and version" do
    it "displays the node matching type, name, and version" do
      result = call("/presentation/ui_modes/display_by_type_name_and_version")[2].body.read

      expect(result).not_to include_sans_whitespace(
        <<~HTML
          <div data-b="post">
            <h1>default</h1>
          </div>
        HTML
      )

      expect(result).to include_sans_whitespace(
        <<~HTML
          <div data-b="post" data-v="one">
            <h1>one</h1>
          </div>
        HTML
      )

      expect(result).not_to include_sans_whitespace(
        <<~HTML
          <div data-b="post">
            <h1>two</h1>
          </div>
        HTML
      )
    end
  end
end
