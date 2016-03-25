=begin rdoc
--------------------------------------------------------------------------------
Added this to distill the additions to the revised data, instead of ingesting it all again.
If we were starting from scratch, it would not be necessary.

The pattern to look for is this:
  :instance ld4l:identifiedBy :identifier .
  :identifier a ld4l:LocalIlsIdentifier.
  :identifier rdf:value "value".

We already have a list of :instance to :identifier, and a list of identifier to value.
--------------------------------------------------------------------------------
=end
require_relative 'distiller_core'

module Ld4lBrowserData
  module AdditionalTriples
    class SecondSiteDistiller
      include Utilities::MainClassHelper
      include DistillerCore
      def initialize
        @usage_text = [
          'Usage is ld4l_distill_site_again \\',
          'source=<source_directory> \\',
          'first_distill=<distilled_directory> \\',
          'target=<target_directory>[~REPLACE] \\',
          'report=<report_file>[~REPLACE] \\'
        ]
      end

      def process_arguments()
        parse_arguments(:source, :first_distill, :target, :report)

        @source_dir = validate_input_directory(:source, "source_directory")
        @distilled_dir = validate_input_directory(:first_distill, "distilled_directory")
        @target_dir = validate_output_directory(:target, "target_directory")
        @report = Report.new('ld4l_distill_site', validate_output_file(:report, "report file"))

        @source_files = find_source_file_paths(/\.nt$/)

        @instance_to_identifiers = in_distilled_dir('instance_to_identifier.txt')
        @identifier_to_value = in_distilled_dir('identifier_to_value.txt')

        @local_ils_identifiers = in_target_dir('local_ils_identifiers.txt')
        @instance_to_local_ils = in_target_dir('instance_to_local_ils.txt')
        @instance_to_ils_values = in_target_dir('instance_to_ils_values.txt')
        @ils_identifier_triples = in_target_dir('ils_identifier_triples.nt')
      end

      def in_distilled_dir(filename)
        File.join(@distilled_dir, filename)
      end

      def create_more_ils_identifiers()
        filter(/LocalIlsIdentifier/, @local_ils_identifiers)
        join(@instance_to_identifiers, 3, @local_ils_identifiers, 1, @instance_to_local_ils, [[1, 1], [1, 3]])
        join(@instance_to_local_ils, 2, @identifier_to_value, 1, @instance_to_ils_values, [[1, 1], [1, 2], [2, 2]])
      end

      ILS_TRIPLES_FORMAT= <<-END
        <%s> <http://bib.ld4l.org/ontology/identifiedBy> <%s> .
        <%s> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://bib.ld4l.org/ontology/LocalIlsIdentifier> .
        <%s> <http://www.w3.org/1999/02/22-rdf-syntax-ns#value> "%s" .
      END

      def create_ils_identifier_triples()
        File.open(@ils_identifier_triples, 'w') do |out|
          File.foreach(@instance_to_ils_values) do |line|
            instance, identifier, value = line.chomp.split(' ', 3)
            out.puts(ILS_TRIPLES_FORMAT % [instance, identifier, identifier, identifier, value])
          end
        end
      end

      def run
        begin
          process_arguments
          create_more_ils_identifiers
          create_ils_identifier_triples
        rescue UserInputError, IllegalStateError
          puts
          puts "ERROR: #{$!}"
          puts
          exit 1
        ensure
          @report.close if @report
        end
      end
    end
  end
end

=begin
=end
