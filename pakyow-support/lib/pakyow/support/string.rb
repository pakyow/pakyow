# frozen_string_literal: true

class String
  def self.normalize_path(path)
    File.join("/", path.gsub("//", "/").chomp("/"))
  end
end
