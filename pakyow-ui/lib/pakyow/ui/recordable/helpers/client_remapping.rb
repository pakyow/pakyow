# frozen_string_literal: true

module Pakyow
  module UI
    module Recordable
      module Helpers
        module ClientRemapping
          def remap_for_client(method_name)
            case method_name
            when :[]
              :get
            when :[]=
              :set
            when :<<
              :add
            when :title=
              :setTitle
            when :html=
              :setHtml
            when :setup_endpoint
              :setupEndpoint
            when :wrap_endpoint_for_removal
              :wrapEndpointForRemoval
            else
              method_name
            end
          end
        end
      end
    end
  end
end
