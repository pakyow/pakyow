require_relative "./shared"

RSpec.describe "populating options for nested data" do
  include_context "options_for"

  let :view do
    Pakyow::Presenter::View.new(
      <<~HTML
        <form binding="post">
          <ul>
            <li binding="tags">
              <label binding="name">
                Tag Name
              </label>

              <input type="text" binding="description">
              <input type="checkbox" binding="enabled" value="true">
            </li>
          </ul>
        </form>
      HTML
    )
  end

  let :options do
    [
      { description: "foo", enabled: true, name: "Foo" },
      { description: "bar", enabled: false, name: "Bar" }
    ]
  end

  it "sets up the fields and labels" do
    expect(form.view.find_all(:tags).count).to be(2)
    expect(form.view.to_s).to include_sans_whitespace(
      <<~HTML
        <li data-b="tags" data-c="form">
          <label data-b="name" data-c="form">Foo</label>
          <input type="text" data-b="description" data-c="form" value="foo" name="post[tags][][description]">
          <input type="checkbox" data-b="enabled" value="true" data-c="form" checked="checked" name="post[tags][][enabled]">
        </li>

        <li data-b="tags" data-c="form">
          <label data-b="name" data-c="form">Bar</label>
          <input type="text" data-b="description" data-c="form" value="bar" name="post[tags][][description]">
          <input type="checkbox" data-b="enabled" value="true" data-c="form" name="post[tags][][enabled]">
        </li>
      HTML
    )
  end

  describe "embedding the unique identifier" do
    context "nested data has an id" do
      let :options do
        [
          { id: 1 },
          { id: 2 }
        ]
      end

      it "embeds the id" do
        expect(form.view.to_s).to include_sans_whitespace(
          <<~HTML
            <li data-b="tags" data-c="form" data-id="1">
              <input type="hidden" name="post[tags][][id]" value="1">
          HTML
        )

        expect(form.view.to_s).to include_sans_whitespace(
          <<~HTML
            <li data-b="tags" data-c="form" data-id="2">
              <input type="hidden" name="post[tags][][id]" value="2">
          HTML
        )
      end
    end

    context "nested data has a primary key" do
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
          object.new(slug: :one),
          object.new(slug: :two)
        ]
      end

      it "embeds the primary key" do
        expect(form.view.to_s).to include_sans_whitespace(
          <<~HTML
            <li data-b="tags" data-c="form">
              <input type="hidden" name="post[tags][][slug]" value="one">
          HTML
        )

        expect(form.view.to_s).to include_sans_whitespace(
          <<~HTML
            <li data-b="tags" data-c="form">
              <input type="hidden" name="post[tags][][slug]" value="two">
          HTML
        )
      end
    end

    context "nested data does not have an id or primary key" do
      let :options do
        [
          { foo: 1 },
          { foo: 2 }
        ]
      end

      it "does not embed an identifier" do
        expect(form.view.to_s).to_not include_sans_whitespace("<li data-b=\"tags\" data-c=\"form\"><input type=\"hidden\"")
      end
    end
  end

  describe "populating options for a single nested object" do
    let :options do
      { id: 1, description: "foo", enabled: true, name: "Foo" }
    end

    it "sets up the field and label for the object" do
      expect(form.view.find_all(:tags).count).to be(1)
      expect(form.view.to_s).to include_sans_whitespace(
        <<~HTML
          <li data-b="tags" data-c="form" data-id="1">
            <input type="hidden" name="post[tags][id]" value="1">
            <label data-b="name" data-c="form">Foo</label>
            <input type="text" data-b="description" data-c="form" value="foo" name="post[tags][description]">
            <input type="checkbox" data-b="enabled" value="true" data-c="form" checked="checked" name="post[tags][enabled]">
          </li>
        HTML
      )
    end
  end

  describe "populating options for an empty array" do
    let :options do
      []
    end

    it "clears the options" do
      expect(form.view.find_all(:tags).count).to be(0)
    end
  end

  describe "populating options for nil" do
    let :options do
      nil
    end

    it "clears the options" do
      expect(form.view.find_all(:tags).count).to be(0)
    end
  end
end
