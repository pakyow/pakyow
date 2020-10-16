require_relative "./shared"

RSpec.describe "populating options for a select field" do
  include_context "options_for"

  let :view_path do
    "/presentation/forms/options_for/select"
  end

  let :options do
    [[1, "one"], [2, "two"], [3, "three"]]
  end

  it "renders in an expected way" do
    expect(rendered).to include_sans_whitespace(
      <<~HTML
        <form data-b="post:form">
          <select data-b="tag" name="post[tag]">
            <option value="1">one</option>
            <option value="2">two</option>
            <option value="3">three</option>
          </select>

          <script type="text/template" data-b="tag">
            <select data-b="tag">
              <option data-b="name">existing</option>
            </select>
          </script>
        </form>
      HTML
    )
  end

  context "given a block" do
    let :block do
      Proc.new do
        [[1, "one"], [2, "two"], [3, "three"]]
      end
    end

    it "uses options provided by the block" do
      expect(rendered).to include_sans_whitespace(
        <<~HTML
          <form data-b="post:form">
            <select data-b="tag" name="post[tag]">
              <option value="1">one</option>
              <option value="2">two</option>
              <option value="3">three</option>
            </select>

            <script type="text/template" data-b="tag">
              <select data-b="tag">
                <option data-b="name">existing</option>
              </select>
            </script>
          </form>
        HTML
      )
    end
  end

  describe "populating with an array of objects" do
    context "objects have an id" do
      let :options do
        [
          { id: 1, name: "one" },
          { id: 2, name: "two" },
          { id: 3, name: "three" }
        ]
      end

      it "renders in an expected way" do
        expect(rendered).to include_sans_whitespace(
          <<~HTML
            <form data-b="post:form">
              <select data-b="tag" name="post[tag]">
                <option value="1">one</option>
                <option value="2">two</option>
                <option value="3">three</option>
              </select>

              <script type="text/template" data-b="tag">
                <select data-b="tag">
                  <option data-b="name">existing</option>
                </select>
              </script>
            </form>
          HTML
        )
      end
    end

    context "object class defines a primary key" do
      let :object do
        require "pakyow/support/bindable"

        Class.new do
          include Pakyow::Support::Bindable

          def self.primary_key_field
            :slug
          end

          def initialize(values)
            @values = values
          end

          def method_missing(method, *args)
            if @values.include?(method)
              @values[method]
            else
              super
            end
          end

          def respond_to_missing?(method, *args)
            @values.include?(method) || super
          end
        end
      end

      let :options do
        [
          object.new(slug: :one, name: "One"),
          object.new(slug: :two, name: "Two"),
          object.new(slug: :three, name: "Three")
        ]
      end

      it "renders in an expected way" do
        expect(rendered).to include_sans_whitespace(
          <<~HTML
            <form data-b="post:form">
              <select data-b="tag" name="post[tag]">
                <option value="one">One</option>
                <option value="two">Two</option>
                <option value="three">Three</option>
              </select>

              <script type="text/template" data-b="tag">
                <select data-b="tag">
                  <option data-b="name">existing</option>
                </select>
              </script>
            </form>
          HTML
        )
      end
    end

    context "object does not have an id or primary key" do
      let :options do
        [
          { slug: :one, name: "One" },
          { slug: :two, name: "Two" },
          { slug: :three, name: "Three" }
        ]
      end

      it "renders in an expected way" do
        expect(rendered).to include_sans_whitespace(
          <<~HTML
            <form data-b="post:form">
              <select data-b="tag" name="post[tag]">
                <option value="">One</option>
                <option value="">Two</option>
                <option value="">Three</option>
              </select>

              <script type="text/template" data-b="tag">
                <select data-b="tag">
                  <option data-b="name">existing</option>
                </select>
              </script>
            </form>
          HTML
        )
      end
    end

    context "field specifies the submitted value" do
      let :view_path do
        "/presentation/forms/options_for/select/with_binding"
      end

      let :options do
        [
          { id: 1, slug: :one, name: "One" },
          { id: 2, slug: :two, name: "Two" },
          { id: 3, slug: :three, name: "Three" }
        ]
      end

      it "renders in an expected way" do
        expect(rendered).to include_sans_whitespace(
          <<~HTML
            <form data-b="post:form">
              <select data-b="tag.slug" name="post[tag]">
                <option value="one">One</option>
                <option value="two">Two</option>
                <option value="three">Three</option>
              </select>

              <script type="text/template" data-b="tag.slug">
                <select data-b="tag.slug">
                  <option data-b="name">existing</option>
                </select>
              </script>
            </form>
          HTML
        )
      end
    end

    context "field does not specify a presentation value" do
      let :view_path do
        "/presentation/forms/options_for/select/without_presentation"
      end

      let :options do
        [
          { id: 1, slug: :one, name: "One" },
          { id: 2, slug: :two, name: "Two" },
          { id: 3, slug: :three, name: "Three" }
        ]
      end

      it "renders in an expected way" do
        expect(rendered).to include_sans_whitespace(
          <<~HTML
            <form data-b="post:form">
              <select data-b="tag.slug" name="post[tag]">
                <option value="one"></option>
                <option value="two"></option>
                <option value="three"></option>
              </select>

              <script type="text/template" data-b="tag.slug">
                <select data-b="tag.slug">
                  <option>existing</option>
                </select>
              </script>
            </form>
          HTML
        )
      end
    end
  end

  describe "populating with a single object" do
    let :options do
      { id: 1, name: "one" }
    end

    it "renders in an expected way" do
      expect(rendered).to include_sans_whitespace(
        <<~HTML
          <form data-b="post:form">
            <select data-b="tag" name="post[tag]">
              <option value="1">one</option>
            </select>

            <script type="text/template" data-b="tag">
              <select data-b="tag">
                <option data-b="name">existing</option>
              </select>
            </script>
          </form>
        HTML
      )
    end
  end

  describe "populating with an empty array" do
    let :options do
      []
    end

    it "renders in an expected way" do
      expect(rendered).to include_sans_whitespace(
        <<~HTML
          <form data-b="post:form">
            <select data-b="tag" name="post[tag]">
            </select>

            <script type="text/template" data-b="tag">
              <select data-b="tag">
                <option data-b="name">existing</option>
              </select>
            </script>
          </form>
        HTML
      )
    end
  end

  describe "populating with nil" do
    let :options do
      nil
    end

    it "renders in an expected way" do
      expect(rendered).to include_sans_whitespace(
        <<~HTML
          <form data-b="post:form">
            <select data-b="tag" name="post[tag]">
            </select>

            <script type="text/template" data-b="tag">
              <select data-b="tag">
                <option data-b="name">existing</option>
              </select>
            </script>
          </form>
        HTML
      )
    end
  end
end
