=begin rdoc
--------------------------------------------------------------------------------

One of the WIT processes has generated a whole slew of JSON stats files. Merge
them together and display the result.

Can we do this in a generalized way?

--------------------------------------------------------------------------------
=end
require 'json'

require_relative 'compile_stats/json_stats_accumulator'

module Ld4lBrowserData
  module WhateverItTakes
    class CompileStats

      FIRST_STATS = <<-END
     {
        "agents": {
          "predicates": {
            "http://www.w3.org/1999/02/22-rdf-syntax-ns#type": {
              "docs_count": 73,
              "occurences": 73
            },
            "http://bib.ld4l.org/ontology/identifiedBy": {
              "docs_count": 4,
              "occurences": 5
            }
          },
          "values": {
            "classes": {
              "docs_count": 73,
              "occurences": 73
            },
            "created": {
              "docs_count": 3,
              "occurences": 3
            }
          },
          "warnings": {
            "No contributed": {
              "count": 11,
              "examples": [
                "http://draft.ld4l.org/cornell/10017person13",
                "http://draft.ld4l.org/cornell/10021person15",
                "http://draft.ld4l.org/cornell/10023organization15",
                "http://draft.ld4l.org/cornell/10029person20",
                "http://draft.ld4l.org/cornell/10034organization29",
                "http://draft.ld4l.org/cornell/10038person28",
                "http://draft.ld4l.org/cornell/10047person37",
                "http://draft.ld4l.org/cornell/10052organization44",
                "http://draft.ld4l.org/cornell/10053organization44",
                "http://draft.ld4l.org/cornell/10055person45"
              ]
            }
          }
        },
        "instances": {
          "predicates": {
            "http://bib.ld4l.org/ontology/illustrationNote": {
              "docs_count": 35,
              "occurences": 35
            },
            "http://bib.ld4l.org/ontology/legacy/supplementaryContentNote": {
              "docs_count": 25,
              "occurences": 26
            }
          },
          "values": {
            "supplementary_content_notes": {
              "docs_count": 25,
              "occurences": 26
            }
          },
          "warnings": {
            "No identifiers": {
              "count": 1,
              "examples": [
                "http://draft.ld4l.org/cornell/10059instance65"
              ]
            }
          }
        },
        "works": {
          "predicates": {
            "http://purl.org/dc/terms/relation": {
              "docs_count": 5,
              "occurences": 5
            }
          },
          "values": {
            "related": {
              "docs_count": 10,
              "occurences": 10
            }
          },
          "warnings": {
            "No languages": {
              "count": 28,
              "examples": [
                "http://draft.ld4l.org/cornell/10017work16",
                "http://draft.ld4l.org/cornell/10017work9"
              ]
            }
          }
        }
      } 
     END
      
      SECOND_STATS = <<-END
     {
        "agents": {
          "predicates": {
            "http://bib.ld4l.org/ontology/identifiedBy": {
              "docs_count": 4,
              "occurences": 5
            }
          },
          "values": {
            "classes": {
              "docs_count": 73,
              "occurences": 73
            },
            "created": {
              "docs_count": 1,
              "occurences": 1
            }
          },
          "warnings": {
            "No contributed": {
              "count": 11,
              "examples": [
                "http://draft.ld4l.org/cornell/10017person13",
                "http://draft.ld4l.org/cornell/10021person15",
                "http://draft.ld4l.org/cornell/10023organization15",
                "http://draft.ld4l.org/cornell/10029person20",
                "http://draft.ld4l.org/cornell/10034organization29",
                "http://draft.ld4l.org/cornell/10038person28",
                "http://draft.ld4l.org/cornell/10047person37",
                "http://draft.ld4l.org/cornell/10052organization44",
                "http://draft.ld4l.org/cornell/10053organization44",
                "http://draft.ld4l.org/cornell/10055person45"
              ]
            }
          }
        },
        "instances": {
          "widgets": {
            "therbligs": [1, 2]
          },
          "predicates": {
            "http://bib.ld4l.org/ontology/illustrationNote": {
              "docs_count": 35,
              "occurences": 35
            },
            "http://bib.ld4l.org/ontology/legacy/supplementaryContentNote": {
              "docs_count": 25,
              "occurences": 26
            }
          },
          "values": {
            "silly_values": {
              "count": 25,
              "one": 26,
              "two": 26
            }
          },
          "warnings": {
            "No identifiers": {
              "count": 1,
              "examples": [
                "http://draft.ld4l.org/cornell/10059instance65"
              ]
            }
          }
        },
        "works": {
          "predicates": {
            "http://purl.org/dc/terms/relation": {
              "docs_count": 5,
              "occurences": 5
            }
          },
          "values": {
            "related": {
              "docs_count": 10,
              "occurences": 10
            }
          },
          "warnings": {
            "No languages": {
              "count": 28,
              "examples": [
                "http://draft.ld4l.org/cornell/10017work16",
                "http://draft.ld4l.org/cornell/10017work9"
              ]
            }
          }
        }
      } 
     END
      
      def run
        first_stats = JSON.load(FIRST_STATS)
        second_stats = JSON.load(SECOND_STATS)
        accumulator = JsonStatsAccumulator.new(max_array_size: 6)
        accumulator << first_stats
        accumulator << second_stats
        summary = accumulator.summary
        puts JSON::pretty_generate(summary)
      end
    end
  end
end
