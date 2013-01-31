require 'support/helper'

class CacheTest < MiniTest::Unit::TestCase
  def setup
    @cache = Cache.new
  end

  def test_stored_value_is_retrievable_by_key
    k = :foo
    v = :bar

    @cache.put(k, v)

    assert_equal @cache.get(k), v
    assert_equal @cache.get(v), nil
  end

  def test_value_obtainable_from_proc
    k = :foo
    v = :bar

    @cache.get(k) { v }
    assert_equal @cache.get(k), v
  end

  def test_value_not_overridden_by_proc
    k = :foo
    v1 = :bar
    v2 = :foobar

    @cache.put(k, v1)
    @cache.get(k) { v2 }
    assert_equal @cache.get(k), v1
  end
end
