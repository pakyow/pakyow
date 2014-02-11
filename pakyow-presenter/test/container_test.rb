require_relative 'support/helper'

describe Container do
  before do
    capture_stdout do
      @store = ViewStore.new('test/support/views')
    end
  end
end
