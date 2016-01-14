#! /bin/bash
#
# Check the command-line
#
if [ $# -lt 1 ]; then
  echo "Specify a data directory."
  exit 1
fi

source="$1/adding_triples/work_to_workID.txt"
target="$1/adding_triples/adding_workids.nt"

if [ ! -f $source ]; then
  echo "$source doesn't exist."
  exit 1
fi

#
# Create a triple for each line.
#
cat $source | \
   awk '{
         printf("<%s> <http://www.w3.org/2000/01/rdf-schema#seeAlso> <http://worldcat.org/entity/work/id/%s> .\n", $1, $2)
      }
   ' > $target
