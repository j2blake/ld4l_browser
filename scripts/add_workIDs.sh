#! /bin/bash
#
# Check the command-line
#
if [ $# -lt 1 ]; then
  echo "Specify a data directory."
  exit 1
fi

if [ ! -d $1 ]; then
  echo "Directory $1 doesn't exist."
  exit 1
fi

if [ ! -d $1/adding_triples ]; then
  echo "Directory $1/adding_triples doesn't exist."
  exit 1
fi

#
# Create a triple for each line.
#
cat $1/adding_triples/work_to_workID.txt | \
   awk '{
         printf("<%s> <http://www.w3.org/2000/01/rdf-schema#seeAlso> <http://worldcat.org/entity/work/id/%s> .\n", $1, $4)
      }
   ' > $1/adding_triples/adding_workids.nt
