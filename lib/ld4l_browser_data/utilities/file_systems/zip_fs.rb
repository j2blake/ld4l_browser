require 'zip'
require 'fileutils'

module Ld4lBrowserData
  module Utilities
    module FileSystems
      class ZipFS
        DEFAULT_PARAMS = {
          :directory => '/DATA/DIR/NOT/SPECIFIED',
          :prefix => 'http://draft.ld4l.org/'}

        def initialize(params)
          @settings = DEFAULT_PARAMS.merge(params)
          @base_dir = @settings[:directory]
          @prefix = @settings[:prefix]
        end

        # return a hash
        def get_bookmark(key)
          path = bookmark_path(key)
          if File.exist?(path)
            File.open(path) do |f|
              JSON.load(f, nil, :symbolize_names => true)
            end
          else
            nil
          end
        end

        # contents is a hash
        def set_bookmark(key, contents)
          path = bookmark_path(key)
          File.open(path, 'w') do |f|
            JSON.dump(contents, f)
          end
        end
        
        def bookmark_path(key)
          File.join(@base_dir, 'bookmark_' + encode(key))
        end

        def acceptable?(uri)
          uri.start_with?(@prefix)
        end

        def write(uri, contents)
          name = remove_prefix(uri)
          hash1, hash2 = hash_it(name)
          safe_name = encode(name)
          dir = File.join(@base_dir, hash1)
          FileUtils.makedirs(dir)

          path = File.join(dir, hash2 + '.zip')
          Zip::File.open(path, Zip::File::CREATE) do |zip_file|
            zip_file.get_output_stream(encode(uri)) do |out|
              out.write (contents)
            end
          end
        end

        def remove_prefix(uri)
          if uri.start_with?(@prefix)
            uri[@prefix.size..-1]
          else
            uri
          end
        end

        def set_void(filename, contents)
          bogus "set_void(#{filename})"
        end

        def hash_it(name)
          hash = Zlib.crc32(name).to_s(16)
          [hash[-4, 2], hash[-2, 2]]
        end

        ENCODE_REGEX = Regexp.compile("[\"*+,<=>?\\\\^|]|[^\x21-\x7e]", nil)

        def encode(name)
          name.gsub(ENCODE_REGEX) { |c| char2hex(c) }.tr('/:.', '=+,')
        end

      end
    end
  end
end

=begin
name = remove_prefix(uri)
hash1, hash2 = hash_it(name)
safe_name = encode(name)
File.join(@root_dir, hash1, hash2, safe_name + '.ttl')

Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
  input_filenames.each do |filename|
    # Two arguments:
    # - The name of the file as it will appear in the archive
    # - The original file, including the path to find it
    zipfile.add(filename, folder + '/' + filename)
  end
  zipfile.get_output_stream("myFile") { |os| os.write "myFile contains just this" }
end

Zip::File.open('my_zip.zip') do |zip_file|
  # Handle entries one by one
  zip_file.each do |entry|
    if entry.directory?
      puts "#{entry.name} is a folder!"
    elsif entry.symlink?
      puts "#{entry.name} is a symlink!"
    elsif entry.file?
      puts "#{entry.name} is a regular file!"

      # Read into memory
      content = entry.get_input_stream.read

      # Output
      puts content
    else
      puts "#{entry.name} is something unknown, oops!"
    end
  end
end
=end
