module Pakyow
  class RouteStore

    def initialize()
      @order = 1
      @store =
          {
              # string routes are stored, for each method, as a hash of 'route'=>{:block=>b,:order=>n,:hooks=>{...}}}
            :string => {:get=>{}, :post=>{}, :put=>{}, :delete=>{}},

              # regex routes are stored, for each method, as an array of hashes {:regex=>r,:block=>b,:order=>n,:vars=>{n=>var},:hooks=>{...}}
              # they are in definition order in the array
            :regex => {:get=>[], :post=>[], :put=>[], :delete=>[]},

              # :order is a global order across both string and regex routes.

              # hooks are blocks stored by name and used to augment returned block from get_block
              :hooks => {}
          }
    end

    def add_route(route_spec, block, method, data, hooks)
      route_spec = normalize_route(route_spec)
      hooks = normalize_hooks(hooks)
      route_to_match, vars = build_route_matcher(route_spec, data)
      
      if route_to_match.is_a?(String)
        @store[:string][method][route_to_match]={:block => block,
                                                 :order => @order,
                                                 :hooks => hooks,
                                                 :data => data}
        @order = @order + 1
      elsif route_to_match.is_a?(Regexp)
        @store[:regex][method] << {:regex => route_to_match,
                                   :block => block,
                                   :order => @order,
                                   :vars => vars,
                                   :hooks => hooks,
                                   :data => data}
        @order = @order + 1
      else
        if Configuration::Base.app.dev_mode == true
          Log.warn("Unsupported route spec class. (#{route_spec.class})")
        else
          Log.warn("Unsupported route spec class. (#{route_spec.class})")
          raise "Unsupported route spec class. (#{route_spec.class})"
        end
      end

    end

    def add_hook(name, hook)
      @store[:hooks][name] = hook
    end

    # returns block, {:vars=>{:var=>matched_value, ...}, :data=>data}
    def get_block(route, method)
      route = normalize_route(route)
      # Get the match for a string route
      string_route_match = @store[:string][method][route]

      # Get first regex match
      regex_route_match = nil
      match_data = nil
      @store[:regex][method].each { |rinfo|
        if match_data = rinfo[:regex].match(route)
          regex_route_match = rinfo
          break
        end
      }

      # return block for match with smaller :order
      if string_route_match && regex_route_match
        if string_route_match[:order] < regex_route_match[:order]
          data = string_route_match[:data]
          return build_hooked_block(string_route_match[:block], string_route_match[:hooks]),
                  {:vars=>{}, :data=>data}
        else
          data = regex_route_match[:data]
          return build_hooked_block(regex_route_match[:block], regex_route_match[:hooks]),
                  {:vars=>build_regex_var_values(regex_route_match[:vars], match_data), :data=>data}
        end
      elsif string_route_match
        data = string_route_match[:data]
        return build_hooked_block(string_route_match[:block], string_route_match[:hooks]),
                {:vars=>{}, :data=>data}
      elsif regex_route_match
        data = regex_route_match[:data]
        return build_hooked_block(regex_route_match[:block], regex_route_match[:hooks]),
                {:vars=>build_regex_var_values(regex_route_match[:vars], match_data), :data=>data}
      else
        return nil,
                {:vars=>{}, :data=>nil}
      end

    end

    private

    def build_hooked_block(block, hooks)
      unless hooks
        return block
      end
      lambda {
        hooks[:before].map { |h|
          @store[:hooks][h].call() if @store[:hooks][h]
        } if hooks && hooks[:before]

        hooks[:around].map { |h|
          @store[:hooks][h].call() if @store[:hooks][h]
        } if hooks && hooks[:around]

        block.call()

        hooks[:around].map { |h|
          @store[:hooks][h].call() if @store[:hooks][h]
        } if hooks && hooks[:around]

        hooks[:after].map { |h|
          @store[:hooks][h].call() if @store[:hooks][h]
        } if hooks && hooks[:after]
      }
    end

    # Returns a regex and an array of variable info
    def build_route_matcher(route_spec, data)
      return route_spec, [] if route_spec.is_a?(Regexp)

      if route_spec.is_a?(String)
        # check for vars
        return route_spec, [] unless route_spec[0,1] == ':' || route_spec.index('/:')
        # we have vars
        if data[:route_type] == :user
          return build_user_route_matcher(route_spec)
        elsif data[:route_type] == :restful
          return build_restful_route_matcher(route_spec, data)
        else
          raise "Unknown route type. (#{data[:route_type]})"
        end
      end

      return route_spec, []
    end

    def build_user_route_matcher(route_spec)
      vars = []
      position_counter = 1
      regex_route = route_spec
      route_segments = route_spec.split('/')
      route_segments.each_with_index { |segment, i|
        if segment.include?(':')
          vars << { :position => position_counter, :var => segment.gsub(':', '') }
          if i == route_segments.length-1 then
            regex_route = regex_route.sub(segment, '((\w|[-.~:@!$\'\(\)\*\+,;])*)')
            position_counter += 2
          else
            regex_route = regex_route.sub(segment, '((\w|[-.~:@!$\'\(\)\*\+,;])*)')
            position_counter += 2
          end
        end
      }
      reg = Regexp.new("^#{regex_route}$")
      return reg, vars
    end

    def build_restful_route_matcher(route_spec, data)
      build_user_route_matcher(route_spec) unless data[:restful][:restful_action] == :show

      #special case for restful show route, can't match 'new' on last var
      vars = []
      position_counter = 1
      regex_route = route_spec
      route_segments = route_spec.split('/')
      route_segments.each_with_index { |segment, i|
        if segment.include?(':')
          vars << { :position => position_counter, :var => segment.gsub(':', '') }
          if i == route_segments.length-1 then
            regex_route = regex_route.sub(segment, '((?!(new\b|.*?\/))(\w|[-.~:@!$\'\(\)\*\+,;])*)')
            position_counter += 1
          else
            regex_route = regex_route.sub(segment, '((\w|[-.~:@!$\'\(\)\*\+,;])*)')
            position_counter += 2
          end
        end
      }
      reg = Regexp.new("^#{regex_route}$")
      return reg, vars
    end

    # remove leading/trailing forward slashes
    def normalize_route(route_spec)
      return route_spec if route_spec.is_a?(Regexp)

      if route_spec.is_a?(String) then
        route_spec = route_spec[1, route_spec.length - 1] if route_spec[0, 1] == '/'
        route_spec = route_spec[0, route_spec.length - 1] if route_spec[route_spec.length - 1, 1] == '/'
        route_spec
      end

      route_spec
    end

    def normalize_hooks(hooks)
      hooks.each_pair { |k,v|
        unless v.is_a?(Array)
          hooks[k] = [v]
        end
      } if hooks
    end

    def build_regex_var_values(vars_info, match_data)
      var_values = {}
      vars_info.each { |vi|
        var_values[vi[:var]] = match_data[vi[:position]]
      }
      var_values
    end

  end
end
