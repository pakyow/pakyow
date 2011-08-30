require 'helper'

class ViewCachingTest < Test::Unit::TestCase
  context "a view cache" do
    setup do
      Configuration::Presenter.view_dir = 'test/views'
      @view_file = '/index.approot/main.html'
      View.cache = {}
      reload_view
    end
    
    should "cache views when view_caching is true" do
      Configuration::Base.presenter.view_caching = true
      
      old_cache = @view.class.cache["#{Configuration::Presenter.view_dir}#{@view_file}"]
      reload_view
      new_cache = @view.class.cache["#{Configuration::Presenter.view_dir}#{@view_file}"]
      
      assert_equal(1, @view.class.cache.length)
      assert(@view.class.cache.include?("#{Configuration::Presenter.view_dir}#{@view_file}"))
      assert_same(old_cache, new_cache)
    end

    should "reset cache when view_caching is false" do
      Configuration::Base.presenter.view_caching = false
      
      old_cache = @view.class.cache["#{Configuration::Presenter.view_dir}#{@view_file}"]
      reload_view
      new_cache = @view.class.cache["#{Configuration::Presenter.view_dir}#{@view_file}"]

      assert_not_same(old_cache, new_cache)
    end
  end
  
  private
  
  def reload_view
    @view = View.new(@view_file)
  end
end
