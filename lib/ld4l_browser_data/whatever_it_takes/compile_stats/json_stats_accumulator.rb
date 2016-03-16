=begin

Join two or more documents into one summary document.

Each non-leaf node is a hash.
The top node may not be a leaf.
A leaf may be a number or an array.
  If a number, and the summary already holds a number in that position, add the two
  If an array, and the summary already holds an array in that position, concatenate the two and limit to max_array_size
  If the summary holds nothing in that position, store the new leaf.

Otherwise, fail.
  top node is not a hash
  number added to array
  array added to number
  non-leaf node exists in the expected position
=end

module Ld4lBrowserData
  module WhateverItTakes
    class CompileStats
      class JsonStatsAccumulator
        class JsonPath
          def initialize(path = [])
            @path = path.dup
          end

          def +(step)
            JsonPath.new(@path + [step])
          end

          def get(tree)
            get_step(@path, tree)
          end

          def get_step(steps, tree)
            remainder = steps.dup
            k = remainder.shift
            if remainder.empty?
              tree[k]
            else
              tree[k] = {} unless tree[k]
              get_step(remainder, tree[k])
            end
          end

          def put(tree, value)
            put_step(@path, tree, value)
          end

          def put_step(steps, tree, value)
            remainder = steps.dup
            k = remainder.shift
            if remainder.empty?
              tree[k] = value
            else
              tree[k] = {} unless tree[k]
              put_step(remainder, tree[k], value)
            end
          end

          def to_s
            @path.join(' => ')
          end
        end

        DEFAULT_PARAMS = {
          max_array_size: 20,
        }

        def initialize(params)
          @settings = DEFAULT_PARAMS.merge(params)
          @summary = {}
        end

        def <<(stats)
          incoming = stats.to_hash
          walk_the_tree(incoming, JsonPath.new)
        end

        def walk_the_tree(hash, path_to_hash)
          hash.each do |k, v|
            path_to_value = path_to_hash + k
            case v
            when Hash
              walk_the_tree(v, path_to_value)
            when Numeric
              update_numeric(path_to_value, v)
            when Array
              update_array(path_to_value, v)
            else
              raise "Value is not Hash, Numeric, or Array. Value is #{v.class} at #{path_to_value}"
            end
          end
        end

        def update_numeric(path, value)
          previous = path.get(@summary)
          case previous
          when Numeric
            path.put(@summary, previous + value)
          when NilClass
            path.put(@summary, value)
          else
            raise "Value is not Numeric or nil at #{path_to_value}"
          end
        end

        def update_array(path, value)
          previous = path.get(@summary)
          case previous
          when Array
            path.put(@summary, (previous + value)[0, @settings[:max_array_size]])
          when NilClass
            path.put(@summary, value)
          else
            raise "Value is not Numeric or nil at #{path_to_value}"
          end
        end

        def summary
          @summary
        end
      end
    end
  end
end

=begin
Walk through the tree, starting with an empty path and the top hash
     If Value is a Number, get the old number (based on Path), add and replace it
     If Value is an Array, get the old Array (based on Path), concatenate, trim, and replace.
     Else crash
=end