require_relative "./shared"

RSpec.describe "populating options in a binding group" do
  include_context "options_for"

  let :view_path do
    "/presentation/forms/options_for/binding_group"
  end

  let :options do
    [[1, "one"], [2, "two"], [3, "three"]]
  end

  it "creates a group for each value, populating the input and label" do
    expect(rendered.gsub(/id=\"([^\"]*)\"/, "").gsub(/for=\"([^\"]*)\"/, "")).to include_sans_whitespace(
      <<~HTML
        <form data-b="post" data-c="form">
          <ul>
            <li data-b="tags" data-c="form">
              <input type="checkbox" name="post[tags][]" value="1">
              <label data-b="name" data-c="form">one</label>
            </li>

            <li data-b="tags" data-c="form">
              <input type="checkbox" name="post[tags][]" value="2">
              <label data-b="name" data-c="form">two</label>
            </li>

            <li data-b="tags" data-c="form">
              <input type="checkbox" name="post[tags][]" value="3">
              <label data-b="name" data-c="form">three</label>
            </li>

            <script type="text/template" data-b="tags" data-c="form">
              <li data-b="tags" data-c="form">
                <input type="checkbox">
                <label data-b="name" data-c="form">Tag Name</label>
              </li>
            </script>
          </ul>
        </form>
      HTML
    )
  end

  it "connects the labels to the inputs" do
    ids = rendered.scan(/id=\"([^\"]*)\"/).flatten
    fors = rendered.scan(/for=\"([^\"]*)\"/).flatten
    expect(ids).to eq(fors)
  end

  context "objects have an id" do
    let :options do
      [
        { id: 1, name: "one" },
        { id: 2, name: "two" },
        { id: 3, name: "three" }
      ]
    end

    it "creates a group for each value, populating the input and label" do
      expect(rendered.gsub(/ id=\"([^\"]*)\"/, "").gsub(/ for=\"([^\"]*)\"/, "")).to include_sans_whitespace(
        <<~HTML
          <form data-b="post" data-c="form">
            <ul>
              <li data-b="tags" data-c="form">
                <input type="checkbox" name="post[tags][]" value="1">
                <label data-b="name" data-c="form">one</label>
              </li>

              <li data-b="tags" data-c="form">
                <input type="checkbox" name="post[tags][]" value="2">
                <label data-b="name" data-c="form">two</label>
              </li>

              <li data-b="tags" data-c="form">
                <input type="checkbox" name="post[tags][]" value="3">
                <label data-b="name" data-c="form">three</label>
              </li>

              <script type="text/template" data-b="tags" data-c="form">
                <li data-b="tags" data-c="form">
                  <input type="checkbox">
                  <label data-b="name" data-c="form">Tag Name</label>
                </li>
              </script>
            </ul>
          </form>
        HTML
      )
    end

    it "connects the labels to the inputs" do
      ids = rendered.scan(/id=\"([^\"]*)\"/).flatten
      fors = rendered.scan(/for=\"([^\"]*)\"/).flatten
      expect(ids).to eq(fors)
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

    it "creates a group for each value, populating the input and label" do
      expect(rendered.gsub(/ id=\"([^\"]*)\"/, "").gsub(/ for=\"([^\"]*)\"/, "")).to include_sans_whitespace(
        <<~HTML
          <form data-b="post" data-c="form">
            <ul>
              <li data-b="tags" data-c="form">
                <input type="checkbox" name="post[tags][]" value="one">
                <label data-b="name" data-c="form">One</label>
              </li>

              <li data-b="tags" data-c="form">
                <input type="checkbox" name="post[tags][]" value="two">
                <label data-b="name" data-c="form">Two</label>
              </li>

              <li data-b="tags" data-c="form">
                <input type="checkbox" name="post[tags][]" value="three">
                <label data-b="name" data-c="form">Three</label>
              </li>

              <script type="text/template" data-b="tags" data-c="form">
                <li data-b="tags" data-c="form">
                  <input type="checkbox">
                  <label data-b="name" data-c="form">Tag Name</label>
                </li>
              </script>
            </ul>
          </form>
        HTML
      )
    end

    it "connects the labels to the inputs" do
      ids = rendered.scan(/id=\"([^\"]*)\"/).flatten
      fors = rendered.scan(/for=\"([^\"]*)\"/).flatten
      expect(ids).to eq(fors)
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

    it "creates a group for each value, populating the label and setting an empty value" do
      expect(rendered.gsub(/ id=\"([^\"]*)\"/, "").gsub(/ for=\"([^\"]*)\"/, "")).to include_sans_whitespace(
        <<~HTML
          <form data-b="post" data-c="form">
            <ul>
              <li data-b="tags" data-c="form">
                <input type="checkbox" name="post[tags][]" value="">
                <label data-b="name" data-c="form">One</label>
              </li>

              <li data-b="tags" data-c="form">
                <input type="checkbox" name="post[tags][]" value="">
                <label data-b="name" data-c="form">Two</label>
              </li>

              <li data-b="tags" data-c="form">
                <input type="checkbox" name="post[tags][]" value="">
                <label data-b="name" data-c="form">Three</label>
              </li>

              <script type="text/template" data-b="tags" data-c="form">
                <li data-b="tags" data-c="form">
                  <input type="checkbox">
                  <label data-b="name" data-c="form">Tag Name</label>
                </li>
              </script>
            </ul>
          </form>
        HTML
      )
    end

    it "connects the labels to the inputs" do
      ids = rendered.scan(/id=\"([^\"]*)\"/).flatten
      fors = rendered.scan(/for=\"([^\"]*)\"/).flatten
      expect(ids).to eq(fors)
    end
  end

  context "field specifies the submitted value" do
    context "specified value is id" do
      let :view_path do
        "/presentation/forms/options_for/binding_group/with_binding_id"
      end

      let :options do
        [
          { id: 1, name: "one" },
          { id: 2, name: "two" },
          { id: 3, name: "three" }
        ]
      end

      it "creates a group for each value, populating the input and label" do
        expect(rendered.gsub(/ id=\"([^\"]*)\"/, "").gsub(/ for=\"([^\"]*)\"/, "")).to include_sans_whitespace(
          <<~HTML
            <form data-b="post" data-c="form">
              <ul>
                <li data-b="tags" data-c="form">
                  <input type="checkbox" data-b="id" data-c="form" name="post[tags][]" value="1">
                  <label data-b="name" data-c="form">one</label>
                </li>

                <li data-b="tags" data-c="form">
                  <input type="checkbox" data-b="id" data-c="form" name="post[tags][]" value="2">
                  <label data-b="name" data-c="form">two</label>
                </li>

                <li data-b="tags" data-c="form">
                  <input type="checkbox" data-b="id" data-c="form" name="post[tags][]" value="3">
                  <label data-b="name" data-c="form">three</label>
                </li>

                <script type="text/template" data-b="tags" data-c="form">
                  <li data-b="tags" data-c="form">
                    <input type="checkbox" data-b="id" data-c="form">
                    <label data-b="name" data-c="form">Tag Name</label>
                  </li>
                </script>
              </ul>
            </form>
          HTML
        )
      end
    end

    context "specified value is the primary key" do
      let :view_path do
        "/presentation/forms/options_for/binding_group/with_binding_pk"
      end

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

      it "creates a group for each value, populating the input and label" do
        expect(rendered.gsub(/ id=\"([^\"]*)\"/, "").gsub(/ for=\"([^\"]*)\"/, "")).to include_sans_whitespace(
          <<~HTML
            <form data-b="post" data-c="form">
              <ul>
                <li data-b="tags" data-c="form">
                  <input type="checkbox" data-b="slug" data-c="form" name="post[tags][]" value="one">
                  <label data-b="name" data-c="form">One</label>
                </li>

                <li data-b="tags" data-c="form">
                  <input type="checkbox" data-b="slug" data-c="form" name="post[tags][]" value="two">
                  <label data-b="name" data-c="form">Two</label>
                </li>

                <li data-b="tags" data-c="form">
                  <input type="checkbox" data-b="slug" data-c="form" name="post[tags][]" value="three">
                  <label data-b="name" data-c="form">Three</label>
                </li>

                <script type="text/template" data-b="tags" data-c="form">
                  <li data-b="tags" data-c="form">
                    <input type="checkbox" data-b="slug" data-c="form">
                    <label data-b="name" data-c="form">Tag Name</label>
                  </li>
                </script>
              </ul>
            </form>
          HTML
        )
      end
    end

    context "specified value is not the id or primary key" do
      let :view_path do
        "/presentation/forms/options_for/binding_group/with_binding_other"
      end

      let :options do
        [
          { foo: 1, name: "one" },
          { foo: 2, name: "two" },
          { foo: 3, name: "three" }
        ]
      end

      it "treats the groups as nested" do
        expect(rendered).to include_sans_whitespace(
          <<~HTML
            <form data-b="post" data-c="form">
              <ul>
                <li data-b="tags" data-c="form">
                  <input type="checkbox" data-b="foo" data-c="form" value="1" name="post[tags][][foo]">
                  <label data-b="name" data-c="form">one</label>
                </li>

                <li data-b="tags" data-c="form">
                  <input type="checkbox" data-b="foo" data-c="form" value="2" name="post[tags][][foo]">
                  <label data-b="name" data-c="form">two</label>
                </li>

                <li data-b="tags" data-c="form">
                  <input type="checkbox" data-b="foo" data-c="form" value="3" name="post[tags][][foo]">
                  <label data-b="name" data-c="form">three</label>
                </li>

                <script type="text/template" data-b="tags" data-c="form">
                  <li data-b="tags" data-c="form">
                    <input type="checkbox" data-b="foo" data-c="form">
                    <label data-b="name" data-c="form">Tag Name</label>
                  </li>
                </script>
              </ul>
            </form>
          HTML
        )
      end
    end
  end

  context "options are empty" do
    let :options do
      []
    end

    it "clears the nested data" do
      expect(rendered).to include_sans_whitespace(
        <<~HTML
          <form data-b="post" data-c="form">
            <ul>
              <script type="text/template" data-b="tags" data-c="form">
                <li data-b="tags" data-c="form">
                  <input type="checkbox">
                  <label data-b="name" data-c="form">Tag Name</label>
                </li>
              </script>
            </ul>
          </form>
        HTML
      )
    end
  end

  context "options are nil" do
    let :options do
      nil
    end

    it "clears the nested data" do
      expect(rendered).to include_sans_whitespace(
        <<~HTML
          <form data-b="post" data-c="form">
            <ul>
              <script type="text/template" data-b="tags" data-c="form">
                <li data-b="tags" data-c="form">
                  <input type="checkbox">
                  <label data-b="name" data-c="form">Tag Name</label>
                </li>
              </script>
            </ul>
          </form>
        HTML
      )
    end
  end
end
