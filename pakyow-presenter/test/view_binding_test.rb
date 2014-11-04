require_relative 'support/helper'

class Contact
  attr_accessor :full_name, :email

  def initialize(full_name, email)
    @full_name = full_name
    @email = email
  end
end

describe "binding data to" do
  before do
    @views = {}

    @views[:many] = create_view_from_string(<<-D)
    <div class="contact" data-scope="contact">
      <span data-prop="full_name">John Doe</span>
      <a data-prop="email">john@example.com</a>
    </div>
    <div class="contact" data-scope="contact">
      <span data-prop="full_name">John Doe</span>
      <a data-prop="email">john@example.com</a>
    </div>
    <div class="contact" data-scope="contact">
      <span data-prop="full_name">John Doe</span>
      <a data-prop="email">john@example.com</a>
    </div>
    D

    @views[:single] = create_view_from_string(<<-D)
    <div class="contact" data-scope="contact">
      <span data-prop="full_name">John Doe</span>
      <a data-prop="email">john@example.com</a>
    </div>
    D

    @views[:unscoped] = create_view_from_string(<<-D)
    <span class="foo" data-prop="foo"></span>
    D
  end

  describe View do
    before do
      @view = View.new
    end

    describe '#with' do
      it "yields context" do
        @view.with { |ctx|
          assert_same @view, ctx
        }
      end

      it "calls block in context of view" do
        ctx = nil
        @view.with {
          ctx = self
        }

        assert_same @view, ctx
      end
    end

    describe '#for' do
      before do
        @data = [{}]
      end

      it "yields each view/datum pair" do
        @view.for(@data) do |ctx, datum|
          assert_same @view, ctx
          assert_same @data[0], datum
        end
      end

      it "calls block in context of view, yielding datum" do
        ctx = nil
        ctx_datum = nil
        @view.for(@data) do |datum|
          ctx = self
          ctx_datum = datum
        end

        assert_same @view, ctx
        assert_same @data[0], ctx_datum
      end

      it "stops when no more views" do
        count = 0
        @view.for(3.times.to_a) do |datum|
          count += 1
        end

        assert count == 1
      end

      it "handles non-array data" do
        data = {}
        @view.for(data) do |ctx, datum|
          assert_same data, datum
        end
      end
    end

    describe '#for_with_index' do
      before do
        @data = [{}]
      end

      it "yields each view/datum pair" do
        @view.for_with_index(@data) do |ctx, datum, i|
          assert_same @view, ctx
          assert_same @data[0], datum
          assert i == 0
        end
      end

      it "calls block in context of view, yielding datum" do
        ctx = nil
        ctx_datum = nil
        ctx_i = nil
        @view.for_with_index(@data) do |datum, i|
          ctx = self
          ctx_datum = datum
          ctx_i = i
        end

        assert_same @view, ctx
        assert_same @data[0], ctx_datum
        assert ctx_i == 0
      end
    end

    describe '#match' do
      before do
        @data = [{}, {}, {}]
        @view = view(:single)
        @view_to_match = @view.scope(:contact)[0]
        @views = @view_to_match.match(@data)
      end

      it "creates a collection of views" do
        assert @views.length == @data.length
      end

      it "sets up each created view" do
        @views.each do |view|
          assert_same @view_to_match.scoped_as, view.scoped_as
        end
      end

      it "removes the original view" do
        assert @view.scope(:contact).length == @data.length
      end
    end

    describe '#repeat' do
      it "matches, then calls for" do
        view = RepeatingTestView.new("")
        view.repeat([{}, {}, {}]) {}

        assert view.calls.include?(:match)
        assert view.calls.include?(:for)
      end
    end

    describe '#repeat_with_index' do
      it "matches, then calls for_with_index" do
        view = RepeatingTestView.new("")
        view.repeat_with_index([{}, {}, {}]) {}

        assert view.calls.include?(:match)
        assert view.calls.include?(:for_with_index)
      end
    end

    describe '#bind' do
      it "yields each view/datum pair" do
        data = {}
        view = view(:single)
        view.bind(data) do |ctx, datum|
          assert_same view, ctx
          assert_same data, datum
        end
      end

      it "calls block in context of view, yielding datum" do
        data = {}
        view = view(:single)
        ctx = nil
        ctx_datum = nil
        ctx_i = nil
        view.bind(data) do |datum|
          ctx = self
          ctx_datum = datum
        end

        assert_same view, ctx
        assert_same data, ctx_datum
      end

      it "binds a hash" do
        data = {:full_name => "Jugyo Kohno", :email => "jugyo@example.com"}
        view = view(:single)
        view.scope(:contact)[0].bind(data)

        doc = ndoc_from_view(view)

        assert_equal data[:full_name], doc.css('.contact span').first.content
        assert_equal data[:email],     doc.css('.contact a').first.content
      end

      it "binds an object without hash lookup syntax" do
        data = Contact.new("Jugyo Kohno", "jugyo@example.com")
        view = view(:single)
        view.scope(:contact)[0].bind(data)

        doc = ndoc_from_view(view)

        assert_equal data.full_name, doc.css('.contact span').first.content
        assert_equal data.email,     doc.css('.contact a').first.content
      end
    end

    describe '#bind_with_index' do
      it "yields each view/datum pair" do
        data = [{}]
        view = view(:single)
        view.bind_with_index(data) do |ctx, datum, i|
          assert_same view, ctx
          assert_same data[0], datum
          assert_equal 0, i
        end
      end

      it "calls block in context of view, yielding datum" do
        data = [{}]
        view = view(:single)
        ctx = nil
        ctx_datum = nil
        ctx_i = nil
        view.bind_with_index(data) do |datum, i|
          ctx = self
          ctx_datum = datum
          ctx_i = i
        end

        assert_same view, ctx
        assert_same data[0], ctx_datum
        assert_equal 0, ctx_i
      end
    end

    describe '#apply' do
      it "matches, then binds" do
        view = RepeatingTestView.new("")
        view.apply([{}, {}, {}]) {}

        assert view.calls.include?(:match)
        assert view.calls.include?(:bind)
      end
    end
  end

  describe ViewCollection do
    before do
      @coll = ViewCollection.new
      @coll << View.new
      @coll << View.new
    end

    describe '#with' do
      it "yields context" do
        @coll.with { |ctx|
          assert_same @coll, ctx
        }
      end

      it "calls block in context of view" do
        ctx = nil
        @coll.with {
          ctx = self
        }

        assert_same @coll, ctx
      end
    end

    describe '#for' do
      before do
        @data = [{}, {}]
      end

      it "yields each view/datum pair" do
        i = 0
        @coll.for(@data) do |ctx, datum|
          assert_same @coll[i], ctx
          assert_same @data[i], datum

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
          assert_same @coll[i], ctx_views[i]
          assert_same @data[i], ctx_data[i]
        end
      end

      it "stops when no more views" do
        count = 0
        @coll.for((@coll.count + 1).times.to_a) do |datum|
          count += 1
        end

        assert count == @coll.count
      end

      it "stops when no more data" do
        count = 0
        @coll.for(@data) do |datum|
          count += 1
        end

        assert count == @data.count
      end

      it "handles non-array data" do
        data = {}
        @coll.for(data) do |ctx, datum|
          assert_same data, datum
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
          assert_same @coll[i], ctx
          assert_same @data[i], datum
          assert i == count

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
          assert_same @coll[i], ctx_views[i]
          assert_same @data[i], ctx_data[i]
          assert_equal i, ctx_is[i]
        end
      end
    end

    describe '#match' do
      before do
        @data = [{}, {}, {}]
        @view = view(:single)
        @view_to_match = @view.scope(:contact)
        @views = @view_to_match.match(@data)
      end

      it "creates a collection of views" do
        assert @views.length == @data.length
      end

      it "sets up each created view" do
        @views.each do |view|
          assert_same @view_to_match[0].scoped_as, view.scoped_as
        end
      end
    end

    describe '#repeat' do
      it "matches, then calls for" do
        view = RepeatingTestViewCollection.new
        view << view(:single)

        view.repeat([{}, {}, {}]) {}

        assert view.calls.include?(:match)
        assert view.calls.include?(:for)
      end
    end

    describe '#repeat_with_index' do
      it "matches, then calls for_with_index" do
        view = RepeatingTestViewCollection.new
        view << view(:single)

        view.repeat_with_index([{}, {}, {}]) {}

        assert view.calls.include?(:match)
        assert view.calls.include?(:for_with_index)
      end
    end

    describe '#bind' do
      before do
        @data = [{}, {}]

        @coll = ViewCollection.new
        @coll << view(:single)
        @coll << view(:single)
      end

      it "yields each view/datum pair" do
        i = 0
        @coll.bind(@data) do |ctx, datum|
          assert_same @coll[i], ctx
          assert_same @data[i], datum

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
          assert_same @coll[i], ctx_views[i]
          assert_same @data[i], ctx_data[i]
        end
      end

      it "binds a hash" do
        data = {:full_name => "Jugyo Kohno", :email => "jugyo@example.com"}
        view = view(:single)
        view.scope(:contact).bind(data)

        doc = ndoc_from_view(view)

        assert_equal data[:full_name], doc.css('.contact span').first.content
        assert_equal data[:email],     doc.css('.contact a').first.content
      end

      it "binds an object" do
        data = Contact.new("Jugyo Kohno", "jugyo@example.com")
        view = view(:single)
        view.scope(:contact).bind(data)

        doc = ndoc_from_view(view)

        assert_equal data.full_name, doc.css('.contact span').first.content
        assert_equal data.email,     doc.css('.contact a').first.content
      end

      it "binds data across views" do
        data = [
          { full_name: 'Bob Dylan', email: 'bob@dylan.com' },
          { full_name: 'Jack White', email: 'jack@white.com' },
          { full_name: 'Charles Mingus', email: 'charles@mingus.com' }
        ]

        view = view(:many).scope(:contact)
        view.bind(data)

        data.each_with_index do |datum, i|
          doc = ndoc_from_view(view[i])
          assert_equal datum[:full_name], doc.css('span').first.content
          assert_equal datum[:email], doc.css('a').first.content
        end
      end

      it "stops binding when no more data" do
        view = view(:many).scope(:contact)
        count = 0
        data = [{}]

        capture_stdout do
          view.bind(data) { |view, datum|
            count += 1
          }
        end

        assert count == data.length
      end

      it "stops binding when no more views" do
        view = view(:many).scope(:contact)
        count = 0
        data = [{}, {}, {}, {}]

        capture_stdout do
          view.bind(data) { |view, datum|
            count += 1
          }
        end

        assert count == view.length
      end
    end

    describe '#bind_with_index' do
      before do
        @data = [{}, {}]

        @coll = ViewCollection.new
        @coll << view(:single)
        @coll << view(:single)
      end

      it "yields each view/datum pair" do
        i = 0
        @coll.bind_with_index(@data) do |ctx, datum, index|
          assert_same @coll[i], ctx
          assert_same @data[i], datum
          assert_equal i, index

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
          assert_same @coll[i], ctx_views[i]
          assert_same @data[i], ctx_data[i]
          assert_same i, ctx_is[i]
        end
      end
    end

    describe '#apply' do
      it "matches, then binds" do
        view = RepeatingTestViewCollection.new
        view << view(:single)

        view.apply([{}, {}, {}]) {}

        assert view.calls.include?(:match)
        assert view.calls.include?(:bind)
      end
    end
  end

  private

  def create_view_from_string(string)
    View.new(string)
  end

  def view(type)
    @views.fetch(type).dup
  end

  def ndoc_from_view(view)
    Nokogiri::HTML.fragment(view.to_s)
  end
end

class RepeatingTestView < Pakyow::Presenter::View
  attr_reader :calls

  def initialize(*args)
    @calls = []
    super
  end

  def repeat(*args, &block)
    @calls << :repeat
    super
  end

  def repeat_with_index(*args, &block)
    @calls << :repeat_with_index
    super
  end

  def match(*args, &block)
    @calls << :match
    super
    self
  end

  def for(*args, &block)
    @calls << :for
    super
  end

  def for_with_index(*args, &block)
    @calls << :for_with_index
    super
  end

  def bind(*args, &block)
    @calls << :bind
    super
  end
end

class RepeatingTestViewCollection < Pakyow::Presenter::ViewCollection
  attr_reader :calls

  def initialize(*args)
    @calls = []
    super
  end

  def repeat(*args, &block)
    @calls << :repeat
    super
  end

  def repeat_with_index(*args, &block)
    @calls << :repeat_with_index
    super
  end

  def match(*args, &block)
    @calls << :match
    super
    self
  end

  def for(*args, &block)
    @calls << :for
    super
  end

  def for_with_index(*args, &block)
    @calls << :for_with_index
    super
  end

  def bind(*args, &block)
    @calls << :bind
    super
  end
end
