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

  def self.normalize_path(path)
    return path if path.is_a?(Regexp)

    path = path[1, path.length - 1] if path[0, 1] == '/'
    path = path[0, path.length - 1] if path[path.length - 1, 1] == '/'
    path
  end
end
