#! /bin/bash
cat distillation.txt | \
   awk '{
         printf("<%s> <http://bib.ld4l.org/ontology/identifiedBy> <%soclc%s> .\n", $1, $1, $4)
         printf("<%soclc%s> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://bib.ld4l.org/ontology/Identifier> .\n", $1, $4)
         printf("<%soclc%s> <http://www.w3.org/1999/02/22-rdf-syntax-ns#value> \"(WORK)%s\"i .\n", $1, $4, $4)
      }
   ' > adding_workids.nt
