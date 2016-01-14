#! /bin/bash
#
# Check the command-line
#
if [ $# -lt 1 ]; then
  echo "Specify a data directory."
  exit 1
fi

source="$1/raw_data"
target="$1/adding_triples"

if [ ! -d $source ]; then
  echo "Directory $source doesn't exist."
  exit 1
fi

if [ ! -d $target ]; then
  echo "Directory $target doesn't exist."
  exit 1
fi

# 
# get all work_to_instance relationships, sorted by instance.
#
echo `date` 'starting instanceOf'
cat $source/bfInstance.nt | \
  awk '
    function strip_angles(uri,      a)
    {
      split(uri, a, "[<>]")
      return a[2] 
    }

    /http:\/\/bib\.ld4l\.org\/ontology\/isInstanceOf/ {
      print strip_angles($3) " " strip_angles($1)
    }
  ' | \
  sort -k2,2 > $target/work_to_instance.txt

#
# get all instance_to_worldcatID(localname) relationships, sorted by instance.
#
echo `date` 'starting worldcat Ids'
cat $source/newAssertions.nt | \
  awk '
    function strip_angles(uri,      a)
    {
      split(uri, a, "[<>]")
      return a[2] 
    }

    function get_localname(uri,      a, size)
    {
      size = split(uri, a, "[<>/]")
      return a[size - 1] 
    }

    /http:\/\/www\.w3\.org\/2002\/07\/owl#sameAs.*http:\/\/www\.worldcat\.org\/oclc/ { 
      print strip_angles($1) " " get_localname($3)
    }
  ' | \
  sort > $target/instance_to_worldcat.txt

#
# combine to get work_to_instance_to_worldcatID, sorted by worldcatID.
#
echo `date` 'starting first join'
join -1 2 -o 1.1,0,2.2 $target/work_to_instance.txt $target/instance_to_worldcat.txt | \
  sort -k3,3 > $target/work_to_instance_to_worldcat.txt

#
# combine with concordance to get work_to_workID, sorted by work.
#
echo `date` 'starting second join'
join -1 3 -o 1.1,2.2 $target/work_to_instance_to_worldcat.txt /home/jeb228/data/concordance/concordance_sorted.txt | \
  sort > $target/work_to_workID.txt
echo `date` 'complete'
