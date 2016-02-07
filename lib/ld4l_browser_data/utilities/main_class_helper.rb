require 'fileutils'

module Ld4lBrowserData
  module Utilities
    module MainClassHelper
      def parse_arguments(cmd_args)
        @args = {}
        ARGV.each do |arg|
          parts = arg.split('=', 2)
          if parts.size == 2
            @args[parts[0].to_sym] = parts[1]
          else
            @args[arg.to_sym] = true
          end
        end
      end

      def validate_input_directory(key, label_text)
        input_dir = @args[key]
        user_input_error("A value for #{key} is required.") unless input_dir

        path = File.expand_path(input_dir)
        user_input_error("#{path} is not a directory.") unless File.directory?(path)

        path
      end

      def validate_input_directories(key, label_text)
        input_dirs = @args[key]
        user_input_error("A value for #{key} is required.") unless input_dirs

        paths = input_dirs.split(',').map {|d| File.expand_path(d) }
        paths.each do |path|
          user_input_error("#{path} is not a directory.") unless File.directory?(path)
        end

        paths
      end

      def validate_output_directory(key, label_text)
        output_dir = @args[key]
        user_input_error("A value for #{key} is required.") unless output_dir

        replace, path = parse_output_path(output_dir)
        user_input_error("Can't create #{path}, parent directory doesn't exist.") unless File.directory?(File.dirname(path))

        if (File.directory?(path))
          replace ||= ok_to_replace?(path)
          user_input_error("Can't replace #{label_text} #{path}") unless replace
          clear_directory(path)
        else
          Dir.mkdir(path)
        end

        path
      end

      def validate_input_file(key, label_text)
        input_file = @args[key]
        user_input_error("A value for #{key} is required.") unless input_file

        path = File.expand_path(input_file)
        user_input_error("#{path} does not exist.") unless File.exist?(path)

        path
      end

      def validate_output_file(key, label_text)
        output_file = @args[key]
        user_input_error("A value for #{key} is required.") unless output_file

        replace, path = parse_output_path(output_file)
        user_input_error("Can't create #{path}, parent directory doesn't exist.") unless File.directory?(File.dirname(path))

        if (File.exist?(path))
          replace ||= ok_to_replace?(path)
          user_input_error("Can't replace #{label_text} #{path}") unless replace
          File.delete(path)
        end

        path
      end

      def validate_integer(props)
        key, label, min = props.values_at(:key, :label, :min)
        value = @args[key]
        user_input_error("A value for #{label} is required.") unless value
        user_input_error("'#{value}' is not a valid integer.") unless value =~ /^-?\d+$/
        integer = value.to_i
        user_input_error("'#{label}' must be at least #{min}") unless integer >= min if min
        integer
      end

      def validate_site_name(props)
        key, label = props.values_at(:key, :label)
        value = @args[key]
        user_input_error("A value for #{label} is required.") unless value
        user_input_error("'#{label}' must be one of #{site_names.inspect}") unless site_names.include?(value)
        value
      end

      def site_names
        ['cornell', 'harvard', 'stanford']
      end

      def check_site_consistency(ignore_surprise, props)
        return if ignore_surprise

        props = props.select{|_, v| v }
        mentioned = props.values.map do |value|
          site_names.select {|s| value.to_s.include?(s)}
        end.flatten.uniq
        return if mentioned.size < 2

        raise UserInputError.new("Fine. forget it") unless ignore_surprises?(mentioned, props)
      end

      def ignore_surprises?(mentioned, props)
        surprises = props.map { |label, value| "#{label} is '#{value}'" }
        puts "  " + surprises.join("\n  ")
        puts "      Ignore this discrepancy: #{mentioned.sort.inspect} (yes/no)?"
        'yes' == STDIN.gets.chomp.downcase
      end

      def clear_directory(path)
        Dir.chdir(path) do |d|
          Dir.entries('.') do |fn|
            FileUtils.remove_entry(fn)
          end
        end
      end

      def parse_output_path(raw_path)
        parts = raw_path.split('~')
        path = File.expand_path(parts[0])
        [parts[1] == 'REPLACE', path]
      end

      def parse_site_name(raw_name)
        parts = raw_name.split('~')
        [parts[1] == 'IGNORE_SURPRISE', parts[0].downcase]
      end

      def ok_to_replace?(path)
        puts "  REPLACE #{path} (yes/no)?"
        raise UserInputError.new("Fine. forget it") unless 'yes' == STDIN.gets.chomp
        true
      end

      def user_input_error(message)
        raise UserInputError.new(message + "\n" + @usage_text.join("\n                   "))
      end

      def connect_triple_store
        selected = TripleStoreController::Selector.selected
        raise UserInputError.new("No triple store selected.") unless selected

        TripleStoreDrivers.select(selected)
        @ts = TripleStoreDrivers.selected

        raise IllegalStateError.new("#{@ts} is not running") unless @ts.running?
        @report.logit("Connected to triple-store: #{@ts}")
      end

      def trap_control_c
        @interrupted = false
        trap("SIGINT") do
          @interrupted = true
        end
      end
    end
  end
end
