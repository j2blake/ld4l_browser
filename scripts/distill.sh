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

if [ ! -d $1/raw_data ]; then
  echo "Directory $1/raw_data doesn't exist."
  exit 1
fi

if [ ! -d $1/adding_triples ]; then
  echo "Directory $1/adding_triples doesn't exist."
  exit 1
fi

# 
# get all work_to_instance relationships, sorted by instance.
#
echo `date` 'starting instanceOf'
cat $1/raw_data/bfInstance.nt | \
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
  sort -k2,2 > $1/adding_triples/work_to_instance.txt

#
# get all instance_to_worldcatID(localname) relationships, sorted by instance.
#
echo `date` 'starting worldcat Ids'
cat $1/raw_data/newAssertions.nt | \
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
  sort > $1/adding_triples/instance_to_worldcat.txt

#
# combine to get work_to_instance_to_worldcatID, sorted by worldcatID.
#
echo `date` 'starting first join'
join -1 2 -o 1.1,0,2.2 $1/adding_triples/work_to_instance.txt $1/adding_triples/instance_to_worldcat.txt | \
  sort -k3,3 > $1/adding_triples/work_to_instance_to_worldcat.txt

#
# combine with concordance to get work_to_workID, sorted by work.
#
echo `date` 'starting second join'
join -1 3 -o 1.1,2.2 $1/adding_triples/work_to_instance_to_worldcat.txt /home/jeb228/data/concordance/concordance_sorted.txt | \
  sort > $1/adding_triples/work_to_workID.txt
echo `date` 'complete'
