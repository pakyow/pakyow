require_relative "./shared"

RSpec.describe "populating options for an input" do
  include_context "options_for"

  let :view_path do
    "/presentation/forms/options_for/input"
  end

  let :options do
    [[1, "one"], [2, "two"], [3, "three"]]
  end

  it "creates an input for each value" do
    expect(rendered).to include_sans_whitespace(
      <<~HTML
        <form data-b="post:form">
          <input type="text" data-b="tags" name="post[tags][]" value="1">
          <input type="text" data-b="tags" name="post[tags][]" value="2">
          <input type="text" data-b="tags" name="post[tags][]" value="3">
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
            <input type="text" data-b="tags" name="post[tags][]" value="1">
            <input type="text" data-b="tags" name="post[tags][]" value="2">
            <input type="text" data-b="tags" name="post[tags][]" value="3">
          </form>
        HTML
      )
    end
  end

  describe "populating with an array of strings" do
    let :options do
      ["one", "two", "three"]
    end

    it "creates an input for each value" do
      expect(rendered).to include_sans_whitespace(
        <<~HTML
          <form data-b="post:form">
            <input type="text" data-b="tags" name="post[tags][]" value="one">
            <input type="text" data-b="tags" name="post[tags][]" value="two">
            <input type="text" data-b="tags" name="post[tags][]" value="three">
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

      it "creates an input for each value" do
        expect(rendered).to include_sans_whitespace(
          <<~HTML
            <form data-b="post:form">
              <input type="text" data-b="tags" name="post[tags][]" value="1">
              <input type="text" data-b="tags" name="post[tags][]" value="2">
              <input type="text" data-b="tags" name="post[tags][]" value="3">
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

      it "creates an input for each value" do
        expect(rendered).to include_sans_whitespace(
          <<~HTML
            <form data-b="post:form">
              <input type="text" data-b="tags" name="post[tags][]" value="one">
              <input type="text" data-b="tags" name="post[tags][]" value="two">
              <input type="text" data-b="tags" name="post[tags][]" value="three">
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

      it "creates a valueless input for each value" do
        expect(rendered).to include_sans_whitespace(
          <<~HTML
            <form data-b="post:form">
              <input type="text" data-b="tags" name="post[tags][]" value="">
              <input type="text" data-b="tags" name="post[tags][]" value="">
              <input type="text" data-b="tags" name="post[tags][]" value="">
            </form>
          HTML
        )
      end
    end

    context "field specifies the submitted value" do
      let :view_path do
        "/presentation/forms/options_for/input/with_binding"
      end

      let :options do
        [
          { id: 1, slug: :one, name: "One" },
          { id: 2, slug: :two, name: "Two" },
          { id: 3, slug: :three, name: "Three" }
        ]
      end

      it "creates an input for each value" do
        expect(rendered).to include_sans_whitespace(
          <<~HTML
            <form data-b="post:form">
              <input type="text" data-b="tags.slug" name="post[tags][]" value="one">
              <input type="text" data-b="tags.slug" name="post[tags][]" value="two">
              <input type="text" data-b="tags.slug" name="post[tags][]" value="three">

              <script type="text/template" data-b="tags.slug">
                <input type="text" data-b="tags.slug">
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

    it "creates an input for the object" do
      expect(rendered).to include_sans_whitespace(
        <<~HTML
          <form data-b="post:form">
            <input type="text" data-b="tags" name="post[tags]" value="1">
          </form>
        HTML
      )
    end
  end

  describe "populating with an empty array" do
    let :options do
      []
    end

    it "clears the options" do
      expect(rendered).to include_sans_whitespace(
        <<~HTML
          <form data-b="post:form"></form>
        HTML
      )
    end
  end

  describe "populating with nil" do
    let :options do
      nil
    end

    it "clears the options" do
      expect(rendered).to include_sans_whitespace(
        <<~HTML
          <form data-b="post:form"></form>
        HTML
      )
    end
  end
end
