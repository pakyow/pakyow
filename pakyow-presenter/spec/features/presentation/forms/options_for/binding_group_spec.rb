require_relative "./shared"

RSpec.describe "populating options in a binding group" do
  include_context "options_for"

  let :view do
    Pakyow::Presenter::View.new(
      <<~HTML
        <form binding="post">
          <ul>
            <li binding="tags">
              <input type="checkbox">
              <label binding="name">
                Tag Name
              </label>
            </li>
          </ul>
        </form>
      HTML
    )
  end

  let :options do
    [[1, "one"], [2, "two"], [3, "three"]]
  end

  it "creates a group for each value, populating the input and label" do
    html = form.view.to_s.gsub(/id=\"([^\"]*)\"/, "").gsub(/for=\"([^\"]*)\"/, "")

    expect(html).to include_sans_whitespace(
      <<~HTML
        <li data-b="tags" data-c="form">
          <input type="checkbox" name="post[tags][]" value="1">
          <label data-b="name" data-c="form">one</label>
        </li>
      HTML
    )

    expect(html).to include_sans_whitespace(
      <<~HTML
        <li data-b="tags" data-c="form">
          <input type="checkbox" name="post[tags][]" value="2">
          <label data-b="name" data-c="form">two</label>
        </li>
      HTML
    )

    expect(html).to include_sans_whitespace(
      <<~HTML
        <li data-b="tags" data-c="form">
          <input type="checkbox" name="post[tags][]" value="3">
          <label data-b="name" data-c="form">three</label>
        </li>
      HTML
    )
  end

  it "connects the labels to the inputs" do
    ids = form.view.to_s.scan(/id=\"([^\"]*)\"/).flatten
    fors = form.view.to_s.scan(/for=\"([^\"]*)\"/).flatten
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
      html = form.view.to_s.gsub(/ id=\"([^\"]*)\"/, "").gsub(/ for=\"([^\"]*)\"/, "")

      expect(html).to include_sans_whitespace(
        <<~HTML
          <li data-b="tags" data-c="form">
            <input type="checkbox" name="post[tags][]" value="1">
            <label data-b="name" data-c="form">one</label>
          </li>
        HTML
      )

      expect(html).to include_sans_whitespace(
        <<~HTML
          <li data-b="tags" data-c="form">
            <input type="checkbox" name="post[tags][]" value="2">
            <label data-b="name" data-c="form">two</label>
          </li>
        HTML
      )

      expect(html).to include_sans_whitespace(
        <<~HTML
          <li data-b="tags" data-c="form">
            <input type="checkbox" name="post[tags][]" value="3">
            <label data-b="name" data-c="form">three</label>
          </li>
        HTML
      )
    end

    it "connects the labels to the inputs" do
      ids = form.view.to_s.scan(/id=\"([^\"]*)\"/).flatten
      fors = form.view.to_s.scan(/for=\"([^\"]*)\"/).flatten
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
      html = form.view.to_s.gsub(/ id=\"([^\"]*)\"/, "").gsub(/ for=\"([^\"]*)\"/, "")

      expect(html).to include_sans_whitespace(
        <<~HTML
          <li data-b="tags" data-c="form">
            <input type="checkbox" name="post[tags][]" value="one">
            <label data-b="name" data-c="form">One</label>
          </li>
        HTML
      )

      expect(html).to include_sans_whitespace(
        <<~HTML
          <li data-b="tags" data-c="form">
            <input type="checkbox" name="post[tags][]" value="two">
            <label data-b="name" data-c="form">Two</label>
          </li>
        HTML
      )

      expect(html).to include_sans_whitespace(
        <<~HTML
          <li data-b="tags" data-c="form">
            <input type="checkbox" name="post[tags][]" value="three">
            <label data-b="name" data-c="form">Three</label>
          </li>
        HTML
      )
    end

    it "connects the labels to the inputs" do
      ids = form.view.to_s.scan(/id=\"([^\"]*)\"/).flatten
      fors = form.view.to_s.scan(/for=\"([^\"]*)\"/).flatten
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
      html = form.view.to_s.gsub(/ id=\"([^\"]*)\"/, "").gsub(/ for=\"([^\"]*)\"/, "")

      expect(html).to include_sans_whitespace(
        <<~HTML
          <li data-b="tags" data-c="form">
            <input type="checkbox" name="post[tags][]" value="">
            <label data-b="name" data-c="form">One</label>
          </li>
        HTML
      )

      expect(html).to include_sans_whitespace(
        <<~HTML
          <li data-b="tags" data-c="form">
            <input type="checkbox" name="post[tags][]" value="">
            <label data-b="name" data-c="form">Two</label>
          </li>
        HTML
      )

      expect(html).to include_sans_whitespace(
        <<~HTML
          <li data-b="tags" data-c="form">
            <input type="checkbox" name="post[tags][]" value="">
            <label data-b="name" data-c="form">Three</label>
          </li>
        HTML
      )
    end

    it "connects the labels to the inputs" do
      ids = form.view.to_s.scan(/id=\"([^\"]*)\"/).flatten
      fors = form.view.to_s.scan(/for=\"([^\"]*)\"/).flatten
      expect(ids).to eq(fors)
    end
  end

  context "field specifies the submitted value" do
    context "specified value is id" do
      let :view do
        Pakyow::Presenter::View.new(
          <<~HTML
            <form binding="post">
              <ul>
                <li binding="tags">
                  <input type="checkbox" binding="id">
                  <label binding="name">
                    Tag Name
                  </label>
                </li>
              </ul>
            </form>
          HTML
        )
      end

      let :options do
        [
          { id: 1, name: "one" },
          { id: 2, name: "two" },
          { id: 3, name: "three" }
        ]
      end

      it "creates a group for each value, populating the input and label" do
        html = form.view.to_s.gsub(/ id=\"([^\"]*)\"/, "").gsub(/ for=\"([^\"]*)\"/, "")

        expect(html).to include_sans_whitespace(
          <<~HTML
            <li data-b="tags" data-c="form">
              <input type="checkbox" data-b="id" data-c="form" name="post[tags][]" value="1">
              <label data-b="name" data-c="form">one</label>
            </li>
          HTML
        )

        expect(html).to include_sans_whitespace(
          <<~HTML
            <li data-b="tags" data-c="form">
              <input type="checkbox" data-b="id" data-c="form" name="post[tags][]" value="2">
              <label data-b="name" data-c="form">two</label>
            </li>
          HTML
        )

        expect(html).to include_sans_whitespace(
          <<~HTML
            <li data-b="tags" data-c="form">
              <input type="checkbox" data-b="id" data-c="form" name="post[tags][]" value="3">
              <label data-b="name" data-c="form">three</label>
            </li>
          HTML
        )
      end
    end

    context "specified value is the primary key" do
      let :view do
        Pakyow::Presenter::View.new(
          <<~HTML
            <form binding="post">
              <ul>
                <li binding="tags">
                  <input type="checkbox" binding="slug">
                  <label binding="name">
                    Tag Name
                  </label>
                </li>
              </ul>
            </form>
          HTML
        )
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
        html = form.view.to_s.gsub(/ id=\"([^\"]*)\"/, "").gsub(/ for=\"([^\"]*)\"/, "")

        expect(html).to include_sans_whitespace(
          <<~HTML
            <li data-b="tags" data-c="form">
              <input type="checkbox" data-b="slug" data-c="form" name="post[tags][]" value="one">
              <label data-b="name" data-c="form">One</label>
            </li>
          HTML
        )

        expect(html).to include_sans_whitespace(
          <<~HTML
            <li data-b="tags" data-c="form">
              <input type="checkbox" data-b="slug" data-c="form" name="post[tags][]" value="two">
              <label data-b="name" data-c="form">Two</label>
            </li>
          HTML
        )

        expect(html).to include_sans_whitespace(
          <<~HTML
            <li data-b="tags" data-c="form">
              <input type="checkbox" data-b="slug" data-c="form" name="post[tags][]" value="three">
              <label data-b="name" data-c="form">Three</label>
            </li>
          HTML
        )
      end
    end

    context "specified value is not the id or primary key" do
      let :view do
        Pakyow::Presenter::View.new(
          <<~HTML
            <form binding="post">
              <ul>
                <li binding="tags">
                  <input type="checkbox" binding="foo">
                  <label binding="name">
                    Tag Name
                  </label>
                </li>
              </ul>
            </form>
          HTML
        )
      end

      let :options do
        [
          { foo: 1, name: "one" },
          { foo: 2, name: "two" },
          { foo: 3, name: "three" }
        ]
      end

      it "treats the groups as nested" do
        expect(form.view.to_s).to include_sans_whitespace(
          <<~HTML
            <li data-b="tags" data-c="form">
              <input type="checkbox" data-b="foo" data-c="form" value="1" checked="checked" name="post[tags][][foo]">
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
      expect(form.view.find(binding)).to be(nil)
    end
  end

  context "options are nil" do
    let :options do
      nil
    end

    it "clears the nested data" do
      expect(form.view.find(binding)).to be(nil)
    end
  end
end
