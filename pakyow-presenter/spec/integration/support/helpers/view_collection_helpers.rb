module ViewCollectionHelpers
  def view_and_collection
    yield(View.new)
    yield(ViewCollection.new)
  end
end
