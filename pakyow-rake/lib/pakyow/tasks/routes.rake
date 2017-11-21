# frozen_string_literal: true

namespace :pakyow do
  desc "List all routes (method, path, group[name])"
  task routes: [:stage] do
    Pakyow::Router.instance.sets.each do |set_data|
      set_name, set = set_data

      Pakyow.logger << "\n#{set_name} routes"

      all_routes = []
      set.routes.each do |route_data|
        method, routes = route_data

        routes.each { |route|
          group = nil
          set.lookup[:grouped].each_pair do |name, routes|
            if routes.values.include?(route)
              group = name
              break
            end
          end

          name = route[2]
          name = "#{group}[#{name}]" if group

          all_routes << {
            method: method,
            path: File.join("/", route[4].to_s),
            name: name
          }
        }
      end

      all_routes.sort { |a, b| a[:path] <=> b[:path] }.each do |route|
        s = "  #{route[:method].upcase}\t#{route[:path]}"
        s << ", #{route[:name]}" if route[:name]
        Pakyow.logger << s
      end

      Pakyow.logger << ""
    end
  end
end
