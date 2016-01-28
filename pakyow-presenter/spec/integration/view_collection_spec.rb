require_relative 'support/int_helper'

  describe Pakyow::Presenter::ViewCollection do
    before do
      @coll = Pakyow::Presenter::ViewCollection.new
      @coll << Pakyow::Presenter::View.new
      @coll << Pakyow::Presenter::View.new
    end

    describe '#with' do
      it "yields context" do
        @coll.with { |ctx|
          expect(@coll).to eq ctx
        }
      end

      it "calls block in context of view" do
        ctx = nil
        @coll.with {
          ctx = self
        }

        expect(@coll).to eq ctx
      end
    end

    describe '#for' do
      before do
        @data = [{}, {}]
      end

      it "yields each view/datum pair" do
        i = 0
        @coll.for(@data) do |ctx, datum|
          expect(@coll[i]).to eq ctx
          expect(@data[i]).to eq datum

          i += 1
        end
      end

      it "calls block in context of view, yielding datum" do
        ctx_views = []
        ctx_data = []
        @coll.for(@data) do |datum|
          ctx_views << self
          ctx_data << datum
        end

        @data.count.times do |i|
          expect(@coll[i]).to eq ctx_views[i]
          expect(@data[i]).to eq ctx_data[i]
        end
      end

      it "stops when no more views" do
        count = 0
        @coll.for((@coll.count + 1).times.to_a) do |datum|
          count += 1
        end

        expect(count).to eq @coll.count
      end

      it "stops when no more data" do
        count = 0
        @coll.for(@data) do |datum|
          count += 1
        end

        expect(count).to eq @data.count
      end

      it "handles non-array data" do
        data = {}
        @coll.for(data) do |ctx, datum|
          expect( data).to eq datum
        end
      end
    end

    describe '#for_with_index' do
      before do
        @data = [{}, {}]
      end

      it "yields each view/datum pair" do
        count = 0
        @coll.for_with_index(@data) do |ctx, datum, i|
          expect(@coll[i]).to eq ctx
          expect(@data[i]).to eq datum
          expect(i).to eq count

          count += 1
        end
      end

      it "calls block in context of view, yielding datum" do
        ctx_views = []
        ctx_data = []
        ctx_is = []
        @coll.for_with_index(@data) do |datum, i|
          ctx_views << self
          ctx_data << datum
          ctx_is << i
        end

        @data.count.times do |i|
          expect(@coll[i]).to eq ctx_views[i]
          expect(@data[i]).to eq ctx_data[i]
          expect(i).to eq ctx_is[i]
        end
      end
    end

    describe '#match' do
      before do
        @data = [{}, {}, {}]
        @view = view_helper(:single)
        @view_to_match = @view.scope(:contact)
        @views = @view_to_match.match(@data)
      end

      it "creates a collection of views" do
        expect(@views.length).to eq @data.length
      end

      it "sets up each created view" do
        @views.each do |view|
    expect(@view_to_match[0].scoped_as).to eq view.scoped_as
        end
      end
    end

    describe '#repeat' do
      it "matches, then calls for" do
        view = RepeatingTestViewCollection.new
        view << view_helper(:single)

        view.repeat([{}, {}, {}]) {}

        expect(view.calls.include?(:match)).to eq true
        expect(view.calls.include?(:for)).to eq true
      end
    end

    describe '#repeat_with_index' do
      it "matches, then calls for_with_index" do
        view = RepeatingTestViewCollection.new
        view << view_helper(:single)

        view.repeat_with_index([{}, {}, {}]) {}

        expect(view.calls.include?(:match)).to eq true
        expect(view.calls.include?(:for_with_index)).to eq true
      end
    end

    describe '#bind' do
      before do
        @data = [{}, {}]

        @coll = Pakyow::Presenter::ViewCollection.new
        @coll << view_helper(:single)
        @coll << view_helper(:single)
      end

      it "yields each view/datum pair" do
        i = 0
        @coll.bind(@data) do |ctx, datum|
          expect(@coll[i]).to eq ctx
          expect(@data[i]).to eq datum

          i += 1
        end
      end

      it "calls block in context of view, yielding datum" do
        ctx_views = []
        ctx_data = []
        @coll.bind(@data) do |datum|
          ctx_views << self
          ctx_data << datum
        end

        @data.count.times do |i|
          expect(@coll[i]).to eq ctx_views[i]
          expect(@data[i]).to eq ctx_data[i]
        end
      end

      it "binds a hash" do
        data = {:full_name => "Jugyo Kohno", :email => "jugyo@example.com"}
        view = view_helper(:single)
        view.scope(:contact).bind(data)

        doc = ndoc_from_view(view)

        expect(data[:full_name]).to eq doc.css('.contact span').first.text
        expect(data[:email]).to eq doc.css('.contact a').first.text
      end

      it "binds an object" do
        data = Contact.new("Jugyo Kohno", "jugyo@example.com")
        view = view_helper(:single)
        view.scope(:contact).bind(data)

        doc = ndoc_from_view(view)

        expect(data.full_name).to eq doc.css('.contact span').first.text
        expect(data.email).to eq doc.css('.contact a').first.text
      end

      it "binds data across views" do
        data = [
          { full_name: 'Bob Dylan', email: 'bob@dylan.com' },
          { full_name: 'Jack White', email: 'jack@white.com' },
          { full_name: 'Charles Mingus', email: 'charles@mingus.com' }
        ]

        view = view_helper(:many).scope(:contact)
        view.bind(data)

        data.each_with_index do |datum, i|
          doc = ndoc_from_view(view[i])
          expect(datum[:full_name]).to eq doc.css('span').first.text
          expect(datum[:email]).to eq doc.css('a').first.text
        end
      end

      it "stops binding when no more data" do
        view = view_helper(:many).scope(:contact)
        count = 0
        data = [{}]

        view.bind(data) { |view, datum|
          count += 1
        }

        expect(count).to eq data.length
      end

      it "stops binding when no more views" do
        view = view_helper(:many).scope(:contact)
        count = 0
        data = [{}, {}, {}, {}]

        view.bind(data) { |view, datum|
          count += 1
        }

        expect(count).to eq view.length
      end
    end

    describe '#bind_with_index' do
      before do
        @data = [{}, {}]

        @coll = Pakyow::Presenter::ViewCollection.new
        @coll << view_helper(:single)
        @coll << view_helper(:single)
      end

      it "yields each view/datum pair" do
        i = 0
        @coll.bind_with_index(@data) do |ctx, datum, index|
          expect(@coll[i]).to eq ctx
          expect(@data[i]).to eq datum
          expect(i).to eq index

          i += 1
        end
      end

      it "calls block in context of view, yielding datum" do
        ctx_views = []
        ctx_data = []
        ctx_is = []
        @coll.bind_with_index(@data) do |datum, i|
          ctx_views << self
          ctx_data << datum
          ctx_is << i
        end

        @data.count.times do |i|
      expect(@coll[i]).to eq ctx_views[i]
      expect(@data[i]).to eq ctx_data[i]
      expect(i).to eq ctx_is[i]
        end
      end
    end

    describe '#apply' do
      it "matches, then binds" do
        view = RepeatingTestViewCollection.new
        view << view_helper(:single)

        view.apply([{}, {}, {}]) {}

        expect(view.calls.include?(:match)).to eq true
        expect(view.calls.include?(:bind)).to eq true
      end
    end
  end
