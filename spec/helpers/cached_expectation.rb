require "fileutils"

module CachedExpectation
  # def expectations_cache_path
  #   raise "not implemented"
  # end

  def cached_expectation(key)
    key_path = expectations_cache_path.join(key)
    expected = yield

    if ENV.include?("RECACHE") || !key_path.exist?
      FileUtils.mkdir_p(key_path.dirname)

      key_path.open("w+") { |file|
        file.write(expected)
      }
    else
      expect(key_path.read).to eq(expected)
    end
  end
end
