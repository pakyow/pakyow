# frozen_string_literal: true

class String
  # split . seperated string at the last .
  def self.split_at_last_dot(s)
    split_index = s.rindex(".")
    return s, nil unless split_index
    left = s[0, split_index]
    right = s[split_index + 1, s.length - (split_index + 1)]
    return left, right
  end

  def self.remove_route_vars(route_spec)
    return unless route_spec
    arr = route_spec.split("/")
    new_arr = []
    arr.each do |e| new_arr << e unless e[0, 1] == ":" end
    ret = new_arr.join("/")
    return "/" if ret == ""
    ret
  end

  def self.parse_path_from_caller(caller)
    caller.match(/^(.+)(:?:\d+(:?:in `.+')?$)/)[1]
  end

  def self.normalize_path(path)
    File.join("/", path.gsub("//", "/").chomp("/"))
  end

  def self.capitalize(string)
    string.slice(0, 1).capitalize + string.slice(1..-1)
  end
end
