=begin
This will create an instance of a file system based on the name of the settings file
Settings files are in ~/triple_store_settings, with names of xxxx.filesystem.
They contain the name of a class and whatever parameters that class requires.

This will also return a list of the names of settings files,
so we can tell the user what he should have said

Each file system class must satisfy these calls:
  initialization(properties)

  acceptable?(uri)

  exist?(uri)

  read(uri)

  write(uri, content)

  how_many -- for display only

  clear

  close   (?)
=end

require_relative 'file_systems/mock_fs'
require_relative 'file_systems/mysql_fs'
require_relative 'file_systems/mysql_zip_fs'
require_relative 'file_systems/zip_fs'

module Ld4lBrowserData
  module Utilities
    module FileSystemUser
      BASE_DIR = File.expand_path('~/triple_store_settings')
      def list_file_systems
        load_file_system_defs
        get_keys_and_names
      end

      def connect_file_system(key)
        load_file_system_defs
        raise UserInputError.new("No such filesystem: #{key}") unless @fs_defs.key?(key)
        settings = Hash[@fs_defs[key]]
        class_name = settings[:class_name]
        begin
          clazz = class_name.split('::').inject(Object) {|o,c| o.const_get c}
          fs = clazz.new(settings)
          @report.logit("Connected to file system: #{fs}") if @report
          fs
        rescue Exception => e
          raise SettingsError.new("Can't create an instance of #{class_name}: #{e.message}")
        end
      end

      def load_file_system_defs
        @fs_defs = {}
        Dir.chdir(BASE_DIR) do |d|
          Dir.entries('.').select{|fn| fn.end_with?('.filesystem')}.each do |fn|
            key = fn[0..-12]
            props = eval(File.read(fn))
            @fs_defs[key] = props
          end
          validate_fs_defs
        end
      end

      def validate_fs_defs()
        raise SettingsError.new("Found no settings files!") if @fs_defs.empty?
        @fs_defs.each do |k, v|
          raise SettingsError.new("Settings file '#{k}' has no settings") unless v
          raise SettingsError.new("Settings file '#{k}' has no value for name") unless v.key?(:name)
          raise SettingsError.new("Settings file '#{k}' has no value for class_name") unless v.key?(:class_name)
        end
      end

      def get_keys_and_names
        @fs_defs.to_a.map do |k, v|
          {:key => k, :name => v[:name]}
        end
      end
    end
  end
end
