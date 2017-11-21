# frozen_string_literal: true

class File
  def self.format(path)
    File.extname(path).delete(".")
  end
end
