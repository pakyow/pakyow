require_relative "./shared"

RSpec.describe "populating options for a radio button" do
  include_context "options_for"

  let :view do
    Pakyow::Presenter::View.new(
      <<~HTML
        <form binding="post">
          <input type="radio" binding="tag">
        </form>
      HTML
    )
  end

  let :options do
    [[1, "one"], [2, "two"], [3, "three"]]
  end

  it "creates an input for each value" do
    expect(form.view.to_s).to include_sans_whitespace(
      <<~HTML
        <input type="radio" data-b="tag" data-c="form" name="post[tag]" value="1">
      HTML
    )

    expect(form.view.to_s).to include_sans_whitespace(
      <<~HTML
        <input type="radio" data-b="tag" data-c="form" name="post[tag]" value="2">
      HTML
    )

    expect(form.view.to_s).to include_sans_whitespace(
      <<~HTML
        <input type="radio" data-b="tag" data-c="form" name="post[tag]" value="3">
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
      expect(form.view.to_s).to include_sans_whitespace(
        <<~HTML
          <input type="radio" data-b="tag" data-c="form" name="post[tag]" value="1">
        HTML
      )

      expect(form.view.to_s).to include_sans_whitespace(
        <<~HTML
          <input type="radio" data-b="tag" data-c="form" name="post[tag]" value="2">
        HTML
      )

      expect(form.view.to_s).to include_sans_whitespace(
        <<~HTML
          <input type="radio" data-b="tag" data-c="form" name="post[tag]" value="3">
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
        expect(form.view.to_s).to include_sans_whitespace(
          <<~HTML
            <input type="radio" data-b="tag" data-c="form" name="post[tag]" value="1">
          HTML
        )

        expect(form.view.to_s).to include_sans_whitespace(
          <<~HTML
            <input type="radio" data-b="tag" data-c="form" name="post[tag]" value="2">
          HTML
        )

        expect(form.view.to_s).to include_sans_whitespace(
          <<~HTML
            <input type="radio" data-b="tag" data-c="form" name="post[tag]" value="3">
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
        expect(form.view.to_s).to include_sans_whitespace(
          <<~HTML
            <input type="radio" data-b="tag" data-c="form" name="post[tag]" value="one">
          HTML
        )

        expect(form.view.to_s).to include_sans_whitespace(
          <<~HTML
            <input type="radio" data-b="tag" data-c="form" name="post[tag]" value="two">
          HTML
        )

        expect(form.view.to_s).to include_sans_whitespace(
          <<~HTML
            <input type="radio" data-b="tag" data-c="form" name="post[tag]" value="three">
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
        expect(form.view.to_s).to include_sans_whitespace(
          <<~HTML
            <input type="radio" data-b="tag" data-c="form" name="post[tag]" value="">
          HTML
        )

        expect(form.view.to_s).to include_sans_whitespace(
          <<~HTML
            <input type="radio" data-b="tag" data-c="form" name="post[tag]" value="">
          HTML
        )

        expect(form.view.to_s).to include_sans_whitespace(
          <<~HTML
            <input type="radio" data-b="tag" data-c="form" name="post[tag]" value="">
          HTML
        )
      end
    end

    context "field specifies the submitted value" do
      let :view do
        Pakyow::Presenter::View.new(
          <<~HTML
            <form binding="post">
              <input type="radio" binding="tag.slug">
            </form>
          HTML
        )
      end

      let :options do
        [
          { id: 1, slug: :one, name: "One" },
          { id: 2, slug: :two, name: "Two" },
          { id: 3, slug: :three, name: "Three" }
        ]
      end

      it "creates an input for each value" do
        expect(form.view.to_s).to include_sans_whitespace(
          <<~HTML
            <input type="radio" data-b="tag.slug" data-c="form" name="post[tag]" value="one">
          HTML
        )

        expect(form.view.to_s).to include_sans_whitespace(
          <<~HTML
            <input type="radio" data-b="tag.slug" data-c="form" name="post[tag]" value="two">
          HTML
        )

        expect(form.view.to_s).to include_sans_whitespace(
          <<~HTML
            <input type="radio" data-b="tag.slug" data-c="form" name="post[tag]" value="three">
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
      expect(form.view.to_s).to include_sans_whitespace(
        <<~HTML
          <input type="radio" data-b="tag" data-c="form" name="post[tag]" value="1">
        HTML
      )
    end
  end

  describe "populating with an empty array" do
    let :options do
      []
    end

    it "clears the options" do
      expect(form.find(binding)).to be(nil)
    end
  end

  describe "populating with nil" do
    let :options do
      nil
    end

    it "clears the options" do
      expect(form.find(binding)).to be(nil)
    end
  end
end
