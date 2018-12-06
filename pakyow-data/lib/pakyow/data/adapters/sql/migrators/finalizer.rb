# frozen_string_literal: true

require "pakyow/data/adapters/sql/migrator"

module Pakyow
  module Data
    module Adapters
      class Sql
        module Migrators
          class Finalizer < Migrator
            attr_reader :migrations

            def initialize(*)
              super
              @migrations = []
            end

            def create_table(name, &block)
              writer = Writer.new(root: true)
              writer.create_table(name, &block)
              @migrations << ["create_#{name}", writer]
            end

            def associate_table(name, with:, &block)
              writer = Writer.new(root: true)
              writer.alter_table(name, &block)
              @migrations << ["associate_#{name}_with_#{with}", writer]
            end

            def alter_table(name, &block)
              writer = Writer.new(root: true)
              writer.alter_table(name, &block)
              @migrations << ["change_#{name}", writer]
            end

            private

            def type_for_attribute(attribute)
              attribute.meta[:migration_type]
            end

            class Writer
              def initialize(root: false)
                @root, @content = root, String.new
              end

              def to_s
                if @root
                  <<~CONTENT
                    change do
                    #{indent(@content.strip)}
                    end
                  CONTENT
                else
                  @content.strip
                end
              end

              def to_ary
                [to_s]
              end

              def method_missing(name, *args, **kwargs, &block)
                method_call = "#{name} #{args_to_string(args, kwargs)}"

                if block_given?
                  @content << <<~CONTENT
                    #{method_call} do
                    #{indent(Writer.new.tap { |writer| writer.instance_exec(&block) }.to_s)}
                    end
                  CONTENT
                else
                  @content << <<~CONTENT
                    #{method_call}
                  CONTENT
                end
              end

              private

              def args_to_string(args, kwargs)
                kwargs.each_with_object(args.map(&:inspect).join(", ")) { |(key, value), string|
                  string << ", #{key}: #{value.inspect}"
                }
              end

              def indent(content)
                content.split("\n").map { |line| "  #{line}" }.join("\n")
              end
            end
          end
        end
      end
    end
  end
end
