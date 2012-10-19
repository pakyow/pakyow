module Pakyow
  module Presenter
    class ViewLookupStore

      # @view_store is a hash structured as:
      #  {
      #      :view_dirs => {
      #                      "/route" => {
      #                                    :root_view => "path/to/root/view",
      #                                    :views => {
      #                                                "view1_name" => "path/to/view1",
      #                                                "view2_name" => "path/to/view2"
      #                                              }
      #                                  },
      #                      "/route/sub" => {
      #                                        :root_view => "path/to/root/view",
      #                                        :views => {
      #                                                    "view1_name" => "path/to/view1",
      #                                                    "view2_name" => "path/to/view2"
      #                                                  }
      #                                      }
      #                    },
      #      :abstract_paths =>  {
      #                            "/abstract/path/file.html" => {:real_path => "/abstract.root1/path/file.html", :file_or_dir => :file},
      #                            "/some/other/path" => {:real_path => "/some/other.root1/path.root2", :file_or_dir => :dir}
      #                          }
      #  }
      # This takes into account that a view directory may have a .root suffix.
      # This not only determines the root view for that route (and sub-routes) but that
      # the route doesn't include the suffix but the path to a view does

      attr_reader(:view_dir)

      def initialize(view_dir)
        @view_store = {:view_dirs => {}, :abstract_paths => {}}
        return unless File.exist?(view_dir)

        @view_dir = view_dir

        # wack the ./ at the beginning if it's there
        view_dir = view_dir.sub(/^\.\//,'')

        # making this a variable in case we change whether we store relative or absolute paths to views
        absolute_path_prefix = view_dir # set to '' to store absolute paths

        default_views = {} # view_basename => path_to_view.html
        if File.exist?(view_dir) then
          default_root_view_file_path = "#{absolute_path_prefix}/#{Configuration::Presenter.default_view}"
          # The logic depends on this traversing top down
          DirUtils.walk_dir(view_dir) { |vpath|
            if File.directory?(vpath)
              parent,route = pakyow_path_to_route_and_parent(vpath, view_dir, :dir)
              # root_view is same as parent unless this route overrides it
              # views are a copy of parent views
              route_root_path = @view_store[:view_dirs][parent] ? @view_store[:view_dirs][parent][:root_view] : default_root_view_file_path
              route_views = @view_store[:view_dirs][parent] ? deep_hash_clone(@view_store[:view_dirs][parent][:views]) : deep_hash_clone(default_views)
              # see if this route overrides root_view
              route_part, root_part = StringUtils.split_at_last_dot(vpath)
              if root_part && root_part.include?('/')
                route_part, root_part = vpath, nil
              end
              if root_part
                if File.exist?("#{vpath}/#{root_part}.html")
                  route_root_path = "#{vpath}/#{root_part}.html".sub(absolute_path_prefix, '')
                elsif route_views[root_part]
                  route_root_path = route_views[root_part]
                else
                  if Configuration::Base.app.dev_mode == true
                    Log.warn("Root view #{root_part} referenced in #{vpath.sub(absolute_path_prefix, '')} was not found.")
                  else
                    Log.error("Root view #{root_part} referenced in #{vpath.sub(absolute_path_prefix, '')} was not found.")
                    raise "Root view #{root_part} referenced in #{vpath.sub(absolute_path_prefix, '')} was not found."
                  end
                end
              end
              @view_store[:view_dirs][route] =
                  {
                    :root_view => route_root_path,
                    :views => route_views
                  }
              # set the abstract path for this dir
              if route == '/'
                r_p = '/'
              else
                r_p = File.join(@view_dir, vpath.sub(absolute_path_prefix, ''))
              end
              @view_store[:abstract_paths][route] = {:real_path => r_p, :file_or_dir => :dir}
              # duplicate real path under routes permuted with leading/trailing slash
              permute_route(route).each { |r| @view_store[:abstract_paths][r] = {:real_path => r_p, :file_or_dir => :dir} } unless route == '/'
            else
              # files here are direct overrides of the route's views
              parent,route = pakyow_path_to_route_and_parent(vpath, view_dir, :file)
              view_key = File.basename(vpath,".*")
              unless @view_store[:view_dirs][route]
                @view_store[:view_dirs][route] = deep_hash_clone(@view_store[:view_dirs][parent])
              end
              @view_store[:view_dirs][route][:views][view_key] = vpath.sub(absolute_path_prefix, '')
              # see if view overrides the root view
              if File.basename(@view_store[:view_dirs][route][:root_view],".*") == view_key
                @view_store[:view_dirs][route][:root_view] = vpath.sub(absolute_path_prefix, '')
              end
              # set the abstract path for this file
              # duplicating real path under route without the leading slash
              r_p = File.join(@view_dir, vpath.sub(absolute_path_prefix, ''))
              if route == '/'
                @view_store[:abstract_paths]["/#{File.basename(vpath)}"] = {:real_path => r_p, :file_or_dir => :file}
                @view_store[:abstract_paths][File.basename(vpath)] = {:real_path => r_p, :file_or_dir => :file}
              else
                route_with_leading_slash = "#{route}/#{File.basename(vpath)}"
                route_without_leading_slash = route_with_leading_slash.sub('/','')
                @view_store[:abstract_paths][route_with_leading_slash] = {:real_path => r_p, :file_or_dir => :file}
                @view_store[:abstract_paths][route_without_leading_slash] = {:real_path => r_p, :file_or_dir => :file}
              end
            end
          }
        end

        # adjust @view_store '.../index' entries to override the parent
        @view_store[:view_dirs].each_pair {|route,info|
          next unless File.basename(route) == "index"
          parent = File.dirname(route)
          @view_store[:view_dirs][parent] = info
        }
        # adjust @view_store entries to have a '.../index' counterpart where missing
        index_counterparts = {}
        @view_store[:view_dirs].each_pair {|route,info|
          next if File.basename(route) == "index" || @view_store[:view_dirs]["#{route}/index"]
          if route == "/"
            index_counterparts["/index"] = info
          else
            index_counterparts["#{route}/index"] = info
          end
        }
        index_counterparts.each_pair { |route,info|
          @view_store[:view_dirs][route] = info
        }
        # Duplicate the info for each combination of route with and without a leading and ending slash
        # All current keys have a leading slash and no trailing slash
        slash_permutations = {}
        @view_store[:view_dirs].each_pair {|route0,info|
          unless route0 == '/' then
            route1, route2, route3 = permute_route(route0)
            slash_permutations[route1] = info
            slash_permutations[route2] = info
            slash_permutations[route3] = info
          end
        }
        slash_permutations.each_pair { |route,info|
          @view_store[:view_dirs][route] = info
        }
      end

      def view_info(route = nil)
        if route
          return @view_store[:view_dirs][route]
        else
          return @view_store[:view_dirs]
        end
      end
      
      def real_path_info(abstract_path = nil)
        if abstract_path then
          @view_store[:abstract_paths][abstract_path]
        else
          @view_store[:abstract_paths]
        end
      end

      def real_path(abstract_path)
        @view_store[:abstract_paths][abstract_path][:real_path] if @view_store[:abstract_paths][abstract_path]
      end
      
      private

      # path can be of the form prefix_path/this/route.root1/overrides/some.root2/root
      # returns the path without the .root_view parts
      def pakyow_path_to_route_and_parent(path, path_prefix, file_or_dir)
        return "","/" if path == path_prefix
        route_path = path.sub("#{path_prefix}/", "")
        unless route_path.include?("/")
          return "","/" if :file == file_or_dir
          return "/","/#{StringUtils.split_at_last_dot(route_path)[0]}"
        end
        route = ""
        parent = ""
        segments = route_path.split('/')
        segments.each_with_index {|s,i|
          next if (i >= segments.length-1 && :file == file_or_dir)
          route_part = StringUtils.split_at_last_dot(s)[0]
          route << "/#{route_part}"
          next if (i >= segments.length-2 && :file == file_or_dir) || (i >= segments.length-1 && :dir == file_or_dir)
          parent << "/#{route_part}"
        }
        parent = "/" if parent == ""
        return parent,route
      end

      # Gonna just use Marshal for now.
      # Can change later if needed since we only need to work
      # on hashes of symbols, strings and hashes.
      def deep_hash_clone(h)
        Marshal.load(Marshal.dump(h))
      end

      # Takes a route with a leading slash and no trailing slash (/route) and
      # returns the three other permutations (/route/, route/, and route).
      def permute_route(route0)
        route3 = route0.sub('/','')
        route2 = "#{route3}/"
        route1 = "#{route0}/"
        return route1,route2,route3
      end

    end
  end
end
