# Ld4lBrowserData

A collection of command-line utilities that are used to process data for search.ld4l.org and draft.ld4l.org.

## The commands

### Triple-store control

* `ts_set`

    Choose the current triple-store from the definitions stored in `~/triple_store_settings`.
    This is not allowed if the current triple-store is running.

* `ts_show`

    Show which triple-store is currently selected, and whether it is running.
 
* `ts_create`

    Initialize a triple-store, based on the current definition. __Not fully implemented.__
 
* `ts_clear`

    Remove all triples from the currently selected triple-store. Not allowed unless the 
    current settings contain `:clear_permitted => true`.
   
* `ts_up`

    Start the currently-selected triple-store.
 
* `ts_down`

    Stop the currently-selected triple-store.

### Scalability tests

* `ld4l_generate_triples` NO
* `ld4l_synthesize_data_copies` 

    Multiply existing N-Triples files to produce a large synthetic data set.

    Creates copies of the original files, but each copy uses distinct URIs for the
    local data. These URIs are created by prefixing the original localname with a
    code that is also added to the filename. So, if a file named `bfInstance.nt` contains this line:  
    `bfInstance.nt` <==> `<http://draft.ld4l.org/cornell/n12345> a <http://bib.ld4l.org/ontology/Work>`  
    then the two generated copies would be  
    `bfInstance--a.nt` <==> `<http://draft.ld4l.org/cornell/a--n12345> a <http://bib.ld4l.org/ontology/Work>`  
    `bfInstance--b.nt` <==> `<http://draft.ld4l.org/cornell/b--n12345> a <http://bib.ld4l.org/ontology/Work>`

### Conditioning the data

* `ld4l_convert_directory_tree`

    Scan through a directory tree looking for RDF/XML files. 
    Create a corresponding directory tree where each RDF/XML file has been converted to NTriples.
    
* `ld4l_scan_directory_tree`

    Scan through a directory tree looking for NTriples files.
    Run each file through a validator and produce a list of issues.
    
* `ld4l_filter_ntriples`

    Scan through a directory tree looking for NTriples files.
    Create a corresponding directory tree where each NTriples file has had erroneous triples
    removed.

* `ld4l_break_nt_files`

    Scan through a directory tree looking for NTriples files.
    Create a corresponding directory tree where each small NTriples file has been copied,
    and each large NTriples file has been broken into smaller files.
    
    The trick is to do it in such a way that no blank node appears in more than one file.

### Generating additional triples
* `ld4l_distill_site` YES
* `ld4l_add_workids` NO
* `ld4l_add_site_links` NO

### Ingest
* `ld4l_ingest_directory_tree` YES
* `ld4l_summarize_ingest_timings` YES

### Indexing
* `ld4l_list_works_instances_agents` NO
* `ld4l_build_solr_index`

    Build the Solr index by querying for all Works, Instances and Agents.
    Interruptible.

* `ld4l_sample_solr_index`

    Add some samples to the Solr index. Index a specified number of Works, and
    the Instances and Agents that relate to them.
    
* `ld4l_index_chosen_uris` NO

### Generating LOD files
* `ld4l_list_all_uris` NO
* `ld4l_create_lod_files` NO
