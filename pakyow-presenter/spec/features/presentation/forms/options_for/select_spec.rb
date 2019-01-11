require_relative "./shared"

RSpec.describe "populating options for a select field" do
  include_context "options_for"

  let :view do
    Pakyow::Presenter::View.new(
      <<~HTML
        <form binding="post">
          <select binding="tag">
            <option binding="name">existing</option>
          </select>
        </form>
      HTML
    )
  end

  let :options do
    [[1, "one"], [2, "two"], [3, "three"]]
  end

  it "clears existing options" do
    expect(form.find(:tag).to_s).not_to include("<option>existing</option>")
  end

  it "creates an option for each value" do
    expect(form.find(:tag).view.object.find_significant_nodes(:option).count).to eq(3)
  end

  it "sets the submitted value for each option" do
    options = form.find(:tag).view.object.find_significant_nodes(:option)
    expect(options[0].attributes[:value]).to eq("1")
    expect(options[1].attributes[:value]).to eq("2")
    expect(options[2].attributes[:value]).to eq("3")
  end

  it "sets the presentation value for each option" do
    options = form.find(:tag).view.object.find_significant_nodes(:option)
    expect(options[0].text).to eq("one")
    expect(options[1].text).to eq("two")
    expect(options[2].text).to eq("three")
  end

  context "given a block" do
    let :block do
      Proc.new do
        [[1, "one"], [2, "two"], [3, "three"]]
      end
    end

    it "uses options provided by the block" do
      expect(form.find(:tag).view.object.find_significant_nodes(:option).count).to eq(3)
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

      it "sets the submitted value for each option" do
        options = form.find(:tag).view.object.find_significant_nodes(:option)
        expect(options[0].attributes[:value]).to eq("1")
        expect(options[1].attributes[:value]).to eq("2")
        expect(options[2].attributes[:value]).to eq("3")
      end

      it "sets the presentation value for each option" do
        options = form.find(:tag).view.object.find_significant_nodes(:option)
        expect(options[0].text).to eq("one")
        expect(options[1].text).to eq("two")
        expect(options[2].text).to eq("three")
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

      it "sets the submitted value for each option" do
        options = form.find(:tag).view.object.find_significant_nodes(:option)
        expect(options[0].attributes[:value]).to eq("one")
        expect(options[1].attributes[:value]).to eq("two")
        expect(options[2].attributes[:value]).to eq("three")
      end

      it "sets the presentation value for each option" do
        options = form.find(:tag).view.object.find_significant_nodes(:option)
        expect(options[0].text).to eq("One")
        expect(options[1].text).to eq("Two")
        expect(options[2].text).to eq("Three")
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

      it "does not set the submitted value for each option" do
        options = form.find(:tag).view.object.find_significant_nodes(:option)
        expect(options[0].attributes[:value]).to eq("")
        expect(options[1].attributes[:value]).to eq("")
        expect(options[2].attributes[:value]).to eq("")
      end

      it "sets the presentation value for each option" do
        options = form.find(:tag).view.object.find_significant_nodes(:option)
        expect(options[0].text).to eq("One")
        expect(options[1].text).to eq("Two")
        expect(options[2].text).to eq("Three")
      end
    end

    context "field specifies the submitted value" do
      let :view do
        Pakyow::Presenter::View.new(
          <<~HTML
            <form binding="post">
              <select binding="tag.slug">
                <option binding="name">existing</option>
              </select>
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

      it "sets the name properly" do
        expect(form.find(:tag).view.object.attributes[:name]).to eq("post[tag]")
      end

      it "sets the submitted value for each option" do
        options = form.find(:tag).view.object.find_significant_nodes(:option)
        expect(options[0].attributes[:value]).to eq("one")
        expect(options[1].attributes[:value]).to eq("two")
        expect(options[2].attributes[:value]).to eq("three")
      end

      it "sets the presentation value for each option" do
        options = form.find(:tag).view.object.find_significant_nodes(:option)
        expect(options[0].text).to eq("One")
        expect(options[1].text).to eq("Two")
        expect(options[2].text).to eq("Three")
      end
    end

    context "field does not specify a presentation value" do
      let :view do
        Pakyow::Presenter::View.new(
          <<~HTML
            <form binding="post">
              <select binding="tag.slug">
                <option>existing</option>
              </select>
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

      it "sets the submitted value for each option" do
        options = form.find(:tag).view.object.find_significant_nodes(:option)
        expect(options[0].attributes[:value]).to eq("one")
        expect(options[1].attributes[:value]).to eq("two")
        expect(options[2].attributes[:value]).to eq("three")
      end

      it "does not set the presentation value for each option" do
        options = form.find(:tag).view.object.find_significant_nodes(:option)
        expect(options[0].text).to eq("")
        expect(options[1].text).to eq("")
        expect(options[2].text).to eq("")
      end
    end
  end

  describe "populating with a single object" do
    let :options do
      { id: 1, name: "one" }
    end

    it "creates a single option for the object" do
      expect(form.find(:tag).view.object.find_significant_nodes(:option).count).to eq(1)
    end

    it "sets the submitted value for each option" do
      options = form.find(:tag).view.object.find_significant_nodes(:option)
      expect(options[0].attributes[:value]).to eq("1")
    end

    it "sets the presentation value for each option" do
      options = form.find(:tag).view.object.find_significant_nodes(:option)
      expect(options[0].text).to eq("one")
    end
  end

  describe "populating with an empty array" do
    let :options do
      []
    end

    it "clears the options" do
      expect(form.find(:tag).view.object.find_significant_nodes(:option).count).to eq(0)
    end
  end

  describe "populating with nil" do
    let :options do
      nil
    end

    it "clears the options" do
      expect(form.find(:tag).view.object.find_significant_nodes(:option).count).to eq(0)
    end
  end
end
