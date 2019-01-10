RSpec.describe "presenting options for a form field" do
  let :presenter do
    Pakyow::Presenter::Presenter.new(view)
  end

  let :view do
    Pakyow::Presenter::View.new(
      <<~HTML
        <form binding="post">
          <input binding="title" type="text">
          <select binding="tag"><option>existing</option></select>
          <input type="checkbox" binding="colors">
          <input type="radio" binding="enabled">
        </form>
      HTML
    )
  end

  let :form do
    presenter.form(:post)
  end

  describe "populating options for a select field" do
    before do
      form.options_for(:tag, [[1, "one"], [2, "two"], [3, "three"]])
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
      before do
        form.options_for(:tag) do
          [[1, "one"], [2, "two"], [3, "three"]]
        end
      end

      it "uses options provided by the block" do
        expect(form.find(:tag).view.object.find_significant_nodes(:option).count).to eq(3)
      end
    end

    describe "populating groups of options" do
      before do
        form.grouped_options_for(:tag, [
                                 ["group1", [[1, "1.1"], [2, "1.2"], [3, "1.3"]]],
                                 ["group2", [[4, "2.1"]]]
                               ]
        )
      end

      it "creates a group for each group" do
        expect(form.find(:tag).view.object.find_significant_nodes(:optgroup).count).to eq(2)
      end

      it "sets the label for each optgroup" do
        groups = form.find(:tag).view.object.find_significant_nodes(:optgroup)
        expect(groups[0].attributes[:label]).to eq("group1")
        expect(groups[1].attributes[:label]).to eq("group2")
      end

      it "creates an option for each value" do
        groups = form.find(:tag).view.object.find_significant_nodes(:optgroup)
        expect(groups[0].find_significant_nodes(:option).count).to eq(3)
        expect(groups[1].find_significant_nodes(:option).count).to eq(1)
      end

      it "sets the submitted value for each option" do
        groups = form.find(:tag).view.object.find_significant_nodes(:optgroup)

        group1_options = groups[0].find_significant_nodes(:option)
        expect(group1_options[0].attributes[:value]).to eq("1")
        expect(group1_options[1].attributes[:value]).to eq("2")
        expect(group1_options[2].attributes[:value]).to eq("3")

        group2_options = groups[1].find_significant_nodes(:option)
        expect(group2_options[0].attributes[:value]).to eq("4")
      end

      it "sets the presentation value for each option" do
        groups = form.find(:tag).view.object.find_significant_nodes(:optgroup)

        group1_options = groups[0].find_significant_nodes(:option)
        expect(group1_options[0].text).to eq("1.1")
        expect(group1_options[1].text).to eq("1.2")
        expect(group1_options[2].text).to eq("1.3")

        group2_options = groups[1].find_significant_nodes(:option)
        expect(group2_options[0].text).to eq("2.1")
      end
    end
  end

  describe "populating options for a checkbox" do
    context "given options" do
      before do
        form.options_for(:colors, [[:red, "Red"], [:green, "Green"], [:blue, "Blue"]])
      end

      it "creates an input for each value" do
        expect(form.view.to_s).to include_sans_whitespace(
          <<~HTML
            <input type="checkbox" data-b="colors" data-c="form" name="post[colors][]" value="red">
          HTML
        )

        expect(form.view.to_s).to include_sans_whitespace(
          <<~HTML
            <input type="checkbox" data-b="colors" data-c="form" name="post[colors][]" value="green">
          HTML
        )

        expect(form.view.to_s).to include_sans_whitespace(
          <<~HTML
            <input type="checkbox" data-b="colors" data-c="form" name="post[colors][]" value="blue">
          HTML
        )
      end
    end

    context "given a block" do
      before do
        form.options_for(:colors) do
          [[:red, "Red"], [:green, "Green"], [:blue, "Blue"]]
        end
      end

      it "uses options provided by the block" do
        expect(form.view.to_s).to include_sans_whitespace(
          <<~HTML
            <input type="checkbox" data-b="colors" data-c="form" name="post[colors][]" value="red">
          HTML
        )

        expect(form.view.to_s).to include_sans_whitespace(
          <<~HTML
            <input type="checkbox" data-b="colors" data-c="form" name="post[colors][]" value="green">
          HTML
        )

        expect(form.view.to_s).to include_sans_whitespace(
          <<~HTML
            <input type="checkbox" data-b="colors" data-c="form" name="post[colors][]" value="blue">
          HTML
        )
      end
    end
  end

  describe "populating options for a radio button" do
    context "given options" do
      before do
        form.options_for(:enabled, [[true, "Yes"], [false, "No"]])
      end

      it "creates an input for each value" do
        expect(form.view.to_s).to include_sans_whitespace(
          <<~HTML
            <input type="radio" data-b="enabled" data-c="form" name="post[enabled]" value="true">
          HTML
        )

        expect(form.view.to_s).to include_sans_whitespace(
          <<~HTML
            <input type="radio" data-b="enabled" data-c="form" name="post[enabled]" value="false">
          HTML
        )
      end
    end

    context "given a block" do
      before do
        form.options_for(:enabled) do
          [[true, "Yes"], [false, "No"]]
        end
      end

      it "uses options provided by the block" do
        expect(form.view.to_s).to include_sans_whitespace(
          <<~HTML
            <input type="radio" data-b="enabled" data-c="form" name="post[enabled]" value="true">
          HTML
        )

        expect(form.view.to_s).to include_sans_whitespace(
          <<~HTML
            <input type="radio" data-b="enabled" data-c="form" name="post[enabled]" value="false">
          HTML
        )
      end
    end
  end

  describe "populating options for an unsupported field" do
    it "fails" do
      expect { form.options_for(:title, []) }.to raise_error(ArgumentError)
    end
  end

  describe "populating options for an nonexistent field" do
    it "fails" do
      expect { form.options_for(:foo, []) }.to raise_error(ArgumentError)
    end
  end

  describe "populating options with an array of objects" do
    let :view do
      Pakyow::Presenter::View.new(
        <<~HTML
          <form binding="post">
            <input type="checkbox" binding="colors">
          </form>
        HTML
      )
    end

    let :options do
      [
        { id: :red, name: "Red" },
        { id: :green, name: "Green" },
        { id: :blue, name: "Blue" }
      ]
    end

    before do
      form.options_for(:colors, options)
    end

    it "sets the value of each option to the object id" do
      expect(form.view.to_s).to include_sans_whitespace(
        <<~HTML
          <input type="checkbox" data-b="colors" data-c="form" name="post[colors][]" value="red">
        HTML
      )

      expect(form.view.to_s).to include_sans_whitespace(
        <<~HTML
          <input type="checkbox" data-b="colors" data-c="form" name="post[colors][]" value="green">
        HTML
      )

      expect(form.view.to_s).to include_sans_whitespace(
        <<~HTML
          <input type="checkbox" data-b="colors" data-c="form" name="post[colors][]" value="blue">
        HTML
      )
    end

    context "field defines a prop" do
      let :options do
        [
          { slug: :red, name: "Red" },
          { slug: :green, name: "Green" },
          { slug: :blue, name: "Blue" }
        ]
      end

      let :view do
        Pakyow::Presenter::View.new(
          <<~HTML
            <form binding="post">
              <input type="checkbox" binding="colors.slug">
            </form>
          HTML
        )
      end

      it "sets the value of each option to the prop value" do
        expect(form.view.to_s).to include_sans_whitespace(
          <<~HTML
            <input type="checkbox" data-b="colors.slug" data-c="form" name="post[colors][]" value="red">
          HTML
        )

        expect(form.view.to_s).to include_sans_whitespace(
          <<~HTML
            <input type="checkbox" data-b="colors.slug" data-c="form" name="post[colors][]" value="green">
          HTML
        )

        expect(form.view.to_s).to include_sans_whitespace(
          <<~HTML
            <input type="checkbox" data-b="colors.slug" data-c="form" name="post[colors][]" value="blue">
          HTML
        )
      end
    end

    context "select defines a prop" do
      let :view do
        Pakyow::Presenter::View.new(
          <<~HTML
            <form binding="post">
              <select binding="colors.slug">
                <option binding="name"></option>
              </select>
            </form>
          HTML
        )
      end

      let :options do
        [
          { slug: :red, name: "Red" },
          { slug: :green, name: "Green" },
          { slug: :blue, name: "Blue" }
        ]
      end

      it "sets the submitted value for each option" do
        options = form.find(:colors).view.object.find_significant_nodes(:option)
        expect(options[0].attributes[:value]).to eq("red")
        expect(options[1].attributes[:value]).to eq("green")
        expect(options[2].attributes[:value]).to eq("blue")
      end
    end

    context "select defines an option binding" do
      let :view do
        Pakyow::Presenter::View.new(
          <<~HTML
            <form binding="post">
              <select binding="colors">
                <option binding="name"></option>
              </select>
            </form>
          HTML
        )
      end

      it "sets the submitted value for each option" do
        options = form.find(:colors).view.object.find_significant_nodes(:option)
        expect(options[0].attributes[:value]).to eq("red")
        expect(options[1].attributes[:value]).to eq("green")
        expect(options[2].attributes[:value]).to eq("blue")
      end

      it "sets the presentation value for each option" do
        options = form.find(:colors).view.object.find_significant_nodes(:option)
        expect(options[0].text).to eq("Red")
        expect(options[1].text).to eq("Green")
        expect(options[2].text).to eq("Blue")
      end
    end
  end
end
