#
# This script doesn't actually work. There are too many interactive prompts to be answered.
# It's intended to show the flow that should happen.
#

#
# Empty the triple-stores
#
cd ~/data/triplestore_data
rm virtuoso_cornell_440K/*
rm virtuoso_harvard_440K/*
rm virtuoso_stanford_440K/*

#
# Generate the added triples
#
cd ~/data/2nd/cornell_440K
ld4l_distill_site source=raw_data target=adding_triples report=_reports/distill_site.txt
cd ~/data/2nd/harvard_440K
ld4l_distill_site source=raw_data target=adding_triples report=_reports/distill_site.txt
cd ~/data/2nd/stanford_440K
ld4l_distill_site source=raw_data target=adding_triples report=_reports/distill_site.txt

cd ~/data/2nd
add_workIDs.sh cornell_440K/
add_workIDs.sh harvard_440K/
add_workIDs.sh stanford_440K/
add_work_links.sh cornell_440K/ harvard_440K/
add_work_links.sh cornell_440K/ stanford_440K/
add_work_links.sh harvard_440K/ stanford_440K/
add_instance_links.sh cornell_440K/ harvard_440K/
add_instance_links.sh cornell_440K/ stanford_440K/
add_instance_links.sh harvard_440K/ stanford_440K/

#
# Ingest and index the data
#
cd ~/ld4l_blacklight
rake jetty:stop
rake jetty:start

cd ~/data/2nd/cornell_440K/
ts_down
ts_set
ts_up
ld4l_ingest_directory_tree raw_data/ http://draft.ld4l.org/cornell _reports/ingest_1.txt 
ld4l_ingest_directory_tree adding_triples/ http://draft.ld4l.org/cornell _reports/ingest_2.txt
ld4l_build_solr_index _reports/build_solr_index.txt

cd ~/data/2nd/harvard_440K/
ts_down
ts_set
ts_up
ld4l_ingest_directory_tree raw_data/ http://draft.ld4l.org/cornell _reports/ingest_1.txt 
ld4l_ingest_directory_tree adding_triples/ http://draft.ld4l.org/cornell _reports/ingest_2.txt
ld4l_build_solr_index _reports/build_solr_index.txt

cd ~/data/2nd/stanford_440K/
ts_down
ts_set
ts_up
ld4l_ingest_directory_tree raw_data/ http://draft.ld4l.org/cornell _reports/ingest_1.txt 
ld4l_ingest_directory_tree adding_triples/ http://draft.ld4l.org/cornell _reports/ingest_2.txt
ld4l_build_solr_index _reports/build_solr_index.txt

