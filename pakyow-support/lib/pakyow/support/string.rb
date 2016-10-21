class String
  # split . seperated string at the last .
  def self.split_at_last_dot(s)
    split_index = s.rindex('.')
    return s,nil unless split_index
    left = s[0,split_index]
    right = s[split_index+1,s.length-(split_index+1)]
    return left,right
  end

  def self.remove_route_vars(route_spec)
    return unless route_spec
    arr = route_spec.split('/')
    new_arr = []
    arr.each {|e| new_arr << e unless e[0,1] == ':'}
    ret = new_arr.join('/')
    return '/' if ret == ''
    return ret
  end

  def self.parse_path_from_caller(caller)
    caller.match(/^(.+)(:?:\d+(:?:in `.+')?$)/)[1]
  end

  TAIL_SLASH_REPLACE_REGEX = /(\/)+$/
  def self.normalize_path(path)
    File.join("/", path.gsub("//", "/").gsub(TAIL_SLASH_REPLACE_REGEX, ""))
  end

  def self.capitalize(string)
    string.slice(0,1).capitalize + string.slice(1..-1)
  end
end
