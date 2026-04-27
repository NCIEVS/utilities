#!/bin/bash

#########################################################
# verify script inputs are correct: filename, graphname, vocabType
# verify file is in load directory
# check if the graph exists prior to a new load: use curl for this check, easy to parse
# if graph exists drop it:  use isql for this step
# clean the db.dba load list
# create graph explicitly
# load the file and commit
#########################################################

################################################
# SHARED VARIABLES, DIRECTORIES, TIMESTAMPING
################################################
source /local/content/virtuoso-misc/scripts/vars.sh


################################################
# LOCAL VARS
################################################
filename="$1"
graphname="$2"
vocabType="$3"

################################################
# start logging
################################################
timestamp "Starting data load script $0" >> "$logfile"

################################################
# NEEDS TO BE RUN AS USER VIRTUOSO
################################################
if ! whoami | grep -q "virtuoso" ; then
    timestamp "ERROR: $0 script needs to be run as user \"virtuoso\". Exiting" >> "$logfile"
    exit 0
fi

################################################
# check input arguments
################################################
if [ "$#" -ne 3 ]
then
    timestamp -e "ERROR: Missing argument, usage:\n\t\t./load_graph.sh filename graphname vocabType\n\t\twhere graphname is an http URI. Exiting." >> "$logfile"
    exit 1
fi
timestamp "Using inputs file $filename, graph name $graphname, and vocabType $vocabType" >> "$logfile"

################################################
# check file exists in load directory
################################################
if [ ! -f "$dataLoadDir/$filename" ]
then
    timestamp "ERROR: File $filename not found in load directory. Exiting." >> "$logfile"
    exit 2
fi

################################################
# check endpoint exists or available in localhost, no remote data loads
################################################
if ! curl --silent --request POST "http://localhost:$sparqlport/sparql/?" --data 'format=text/plain' --data-urlencode 'query=select distinct ?g { graph ?g {?s ?p ?o}}' > /dev/null
then
    timestamp "ERROR: accessing sparql endpoint. curl error code $?" >> "$logfile"
    exit 3
fi



################################################
# delete graph prior to a new load, do not assume the graph was created explicitly, no problem if it's new load & graph doesn't exist.
################################################
timestamp "Deleting graph <$graphname> from DB prior to update" >> "$logfile"
drop_graph="SPARQL DEFINE sql:log-enable 3 DROP SILENT GRAPH <$graphname>"
isql localhost:$virtport dba "$dbapd" << EOF 2>&1 >> "$logfile"
    $drop_graph;
    checkpoint;
    exit;
EOF

################################################
# do the load to an explicitly created graph
################################################
timestamp "Loading file $filename into graph <$graphname>" >> "$logfile"
create_graph="sparql create graph <$graphname>"

isql localhost:$virtport dba "$dbapd" << EOF 2>&1 >> "$logfile"
    delete from DB.DBA.load_list;
    $create_graph;
    ld_dir ('$dataLoadDir', '$filename', '$graphname');
    rdf_loader_run();
    checkpoint;
    exit;
EOF

timestamp "Load of $filename completed successfully" >> "$logfile"


################################################
# check some metrics for the data load, have to pass vocabType for correct tests
################################################
metrics="/local/content/virtuoso-misc/scripts/metrics.sh"
if "$metrics" "$filename" "$graphname" "$vocabType"  ; then
    timestamp "Metrics for loaded $filename completed successfully" >> "$logfile"
else
    timestamp "ERROR: Metrics for loaded $filename did NOt complete, errors on arguments" >> "$logfile"
    exit 4
fi

################################################
# end logging
################################################
timestamp "Ending  data load script $0 successfully" >> "$logfile"

exit 0 ;

