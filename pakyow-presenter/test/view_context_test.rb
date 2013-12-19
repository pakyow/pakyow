require_relative 'support/helper'

describe "View Contexts" do
  it "yields in context of view" do
   view_and_collection { |obj|
      yielded = false

      obj.with do
        yielded = true
        self.must_be_same_as obj
      end

      assert yielded
    }
  end

  it "passes context to block" do
    view_and_collection { |obj|
      yielded = false

      obj.with do |ctx|
        yielded = true
        ctx.must_be_same_as(obj)
      end

      assert yielded
    }
  end

  it "returns the view" do
    view_and_collection { |obj|
      obj.with {}.must_be_same_as obj
    }
  end

  def view_and_collection
    yield(View.new)
    yield(ViewCollection.new)
  end
end
