=begin rdoc
--------------------------------------------------------------------------------

If the triple-store is running, show how many triples it has and ask whether to
continue (this is reminder to clear, if desired).

Ingest into the specified graph name.

Ingest all of the eligible files in the specified directory, and in any
sub-directories. A file is eligible if its name matches the regular expression.
By default, this means files with extensions of .rdf, .owl, .nt, or .ttl.

--------------------------------------------------------------------------------

Usage: ld4l_ingest_directory_tree <directory> <graph_uri> <report_file> [regexp] [REPLACE]

--------------------------------------------------------------------------------
=end

module Ld4lBrowserData
  module Ingesting
    class IngestDirectoryTree
      include Utilities::MainClassHelper
      include Utilities::TripleStoreUser

      USAGE_TEXT = 'Usage is  <> <graph_uri> <report_file> [regexp] [REPLACE]'
      DEFAULT_MATCHER = /.+\.(rdf|owl|nt|ttl)$/
      GRAPH_URI_TEMPLATE = 'http://draft.ld4l.org/%s'
      def initialize
        @usage_text = [
          'Usage is ld4l_ingest_directory_tree \\',
          'source=<source_directory> \\',
          'site=<cornell|stanford|harvard> \\',
          'report=<report_file>[~REPLACE] \\',
          '[IGNORE_SURPRISES]'
        ]

        @filename_matcher = DEFAULT_MATCHER
        @start_time = Time.now
      end

      def process_arguments()
        parse_arguments(:source, :site, :report, :IGNORE_SURPRISES)
        @source_dir = validate_input_directory(:source, "source_directory")
        @graph_uri = GRAPH_URI_TEMPLATE % validate_site_name(key: :site, label: "site name")
        @report = Report.new('ld4l_ingest_directory_tree', validate_output_file(:report, "report file"))
        @report.log_header
      end

      def check_for_surprises
        check_site_consistency(@args[:IGNORE_SURPRISES], {
          'Source directory' => @source_dir,
          'Report path' => @report,
          'Graph name' => @graph_uri,
          'Triple-store name' => @ts
        })
      end

      def confirm_intentions
        @starting_triple_count = @ts.size
        puts "#{@ts} already contains #{@ts.size} triples."
        puts "Continue with the ingest? (yes/no) ?"
        'yes' == STDIN.gets.chomp
      end

      def traverse_the_directory
        Find.find(@source_dir) do |path|
          if File.file?(path) && path =~ @filename_matcher
            elapsed = ingest_file(path)
          end
        end
      end

      def ingest_file(path)
        @report.logit "Ingesting #{path}"
        elapsed = Benchmark.realtime do
          @ts.ingest_file(File.expand_path(path), @graph_uri)
        end
        @report.logit("Ingested %s, %.3f" % [path, elapsed])
      end

      def report
        @report.logit "Start time: %s, starting count: %d" % [@start_time, @starting_triple_count]
        @report.logit "End time:   %s, ending count:   %d" % [Time.now, @ts.size]
      end

      def run
        begin
          process_arguments()
          connect_triple_store
          check_for_surprises

          if confirm_intentions
            traverse_the_directory
            report
          else
            puts
            puts "OK. Skip it."
            puts
          end
        rescue UserInputError
          puts
          puts "ERROR: #{$!}"
          puts
        end
      end
    end
  end
end
