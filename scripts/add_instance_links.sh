#! /bin/bash
#
# Check the command-line
#
if [ $# -lt 2 ]; then
  echo "Specify two data directories."
  exit 1
fi

source1="$1/adding_triples/instance_to_worldcat_all.txt"
source2="$2/adding_triples/instance_to_worldcat_all.txt"

if [ ! -f $source1 ]; then
  echo "$source1 doesn't exist."
  exit 1
fi

if [ ! -f $source2 ]; then
  echo "$source2 doesn't exist."
  exit 1
fi

sorted1="$1/adding_triples/instance_by_worldcat_all.txt"
sorted2="$2/adding_triples/instance_by_worldcat_all.txt"
target1="$1/adding_triples/adding_instance_links_`basename \`cd $2 ; pwd \``.nt"
target2="$2/adding_triples/adding_instance_links_`basename \`cd $1 ; pwd \``.nt"

#
# sort both source files by Work ID
#
sort -k2,2 $source1 > $sorted1
sort -k2,2 $source2 > $sorted2

#
# first pass: link $1 to $2
#
echo "Creating $target1"
join -1 2 -2 2 -o 1.1,2.1 $sorted1 $sorted2 | \
  awk '{
         printf("<%s> <http://www.w3.org/2002/07/owl#sameAs> <%s> .\n", $1, $2)
       }
  ' > $target1

#
# second pass: link $2 to $1
#
echo "Creating $target2"
join -1 2 -2 2 -o 1.1,2.1 $sorted2 $sorted1 | \
  awk '{
         printf("<%s> <http://www.w3.org/2002/07/owl#sameAs> <%s> .\n", $1, $2)
       }
  ' > $target2
