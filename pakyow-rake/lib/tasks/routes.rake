namespace :pakyow do
  desc "List all routes (method, path, group[name])"
  task :routes do
    Pakyow::Router.instance.sets.each {|set_data|
      set_name, set = set_data

      Pakyow.logger << "\n#{set_name} routes"

      all_routes = []
      set.routes.each {|route_data|
        method, routes = route_data

        routes.each {|route|
          group = nil
          set.lookup[:grouped].each_pair {|name,routes|
            if routes.values.include?(route)
              group = name
              break
            end
          }

          name = route[2]
          name = "#{group}[#{name}]" if group

          all_routes << {
            method: method,
            path: File.join('/', route[4]),
            name: name
          }
        }
      }

      all_routes.sort{|a,b| a[:path] <=> b[:path]}.each {|route|
        s = "  #{route[:method].upcase}\t#{route[:path]}"
        s << ", #{route[:name]}" if route[:name]
        Pakyow.logger << s
      }

      Pakyow.logger << ''
    }
  end
end
