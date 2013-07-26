Pakyow::App.define do
  configure(:test) do
    app.src_dir = 'test/support/lib'
    
    presenter.view_stores = { 
      default: "test/support/views",
      test: "test/support/test_views"
    }
  end

  processor(:foo, :bar) do |data|
    'foo' + data
  end
end
