=begin
--------------------------------------------------------------------------------

As with convert_directory, keep the subdirectory structure and corresponding fileames.
When breaking, append to the filename __001, __002, etc.
If the file is small enough, keep the original filename and just copy.

Stupid approach:
  Read a line at a time. Decide whether the line contains one or more blank nodes.
  If it contains a blank node, write it to the blank node file. 
    Otherwise, write to one of the regular files.
  The problem with this is that as many as 30% of the lines contain blank nodes.

Two-pass approach:
  First pass:
    pass through, creating a map of the first and last mention of each blank node.
    record the number of lines in the file.
  Find break points:
    start at the desired break point (max-triples past the previous break point)
    search the map to see if the break poiint is eligible.
    if ineligible, try the next smaller.

    if no eligible break point is found, begin incrementing and checking.
      if found, issue a warning and break it there.
  Second pass:
    read through the file, breaking as determined.

--------------------------------------------------------------------------------

Usage: ld4l_break_nt_files <input_directory> <output_directory> [OVERWRITE] <report_file> [REPLACE] <max_triples>

--------------------------------------------------------------------------------
=end

require_relative 'break_nt_files/breakpoint_finder'
require_relative 'break_nt_files/file_breaker'

module Ld4lBrowserData
  module AdditionalTriples
    class SiteDistiller
      USAGE_TEXT = 'Usage is ld4l_break_nt_files <input_directory> <output_directory> [OVERWRITE] <report_file> [REPLACE] <max_triples>'
    end
  end
end
