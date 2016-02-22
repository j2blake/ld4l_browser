module Ld4lBrowserData
  module Indexing
    class IndexSpecificUris
      class Report
        include Utilities::ReportHelper
        def initialize(path)
          super('ld4l_index_specific_uris', path)
          @good_uri_count = 0
        end

        def next_file(filename)
          logit("Opening file: " + filename)
        end

        def start_at_bookmark(filename, line)
          logit("Starting at line #{line} in #{filename}")
        end

        def record_uri(uri, line_number, filename)
          @good_uri_count += 1
        end
        
        def progress(fn, line_number)
          logit("line %d in %s" % [line_number, fn])
        end

        def log_document_error(type, uri, doc, error)
          backtrace = error.backtrace.join("\n   ")
          if error.respond_to?(:cause)
            logit "%s %s\n%s\n%s\n   %s" % [type, error, error.cause, doc_error_display(doc), backtrace]
          else
            logit "%s %s\n%s\n   %s" % [type, error, doc_error_display(doc), backtrace]
          end
        end

        def doc_error_display(doc)
          if doc
            if doc.respond_to?(:document) && doc.document
              "Solr document: " + doc.document.inspect
            else
              "uri= %s, properties= %s, values= %s" % [doc.uri, doc.properties.inspect, doc.values.inspect]
            end
          else
            ""
          end
        end

        def summarize(doc_factory, bookmark, status=:complete)
          first = bookmark.start[:filename]
          first = 'FIRST' if first.empty?
          last = bookmark[:filename]
          how_many = @good_uri_count

          logit ">>>>>>>INTERRUPTED<<<<<<<\n\n" unless status == :complete
          if status == :complete
            logit("Generated for URIs from %s to %s: processed %d URIs." % [first, last, how_many])
          elsif status == :interrupted
            logit("Interrupted in file %s -- started at %s: processed %d URIs." % [last, first, how_many])
          else
            logit("Error in file %s -- started at %s: processed %d URIs.  \n%s  \n%s" % [last, first, how_many, $!.inspect, $!.backtrace.join("\n")])
          end

          logit [doc_factory.work_stats, doc_factory.instance_stats, doc_factory.agent_stats].join("\n")
        end

      end
    end
  end
end

