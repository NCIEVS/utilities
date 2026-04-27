#!/bin/bash

# call of "$metrics", arguments "$filename" "$graphname" "$vocabType"
# including path to logfile no longer required as it's sourced"


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
timestamp "Starting metrics script $0" >> "$logfile"

################################################
# NEEDS TO BE RUN AS USER VIRTUOSO
################################################
if ! whoami | grep -q "virtuoso" ; then
    timestamp "ERROR: $0 script needs to be run as user \"virtuoso\". Exiting" >> "$logfile"
    exit 0
fi

################################################
# check input params: "$dataLoadDir/$filename" "$graphname" "$vocabType"
################################################
if [ "$#" -ne 3 ]
then
    timestamp -e "ERROR: Missing argument, usage:\n\t\t./metrics.sh filename graphname vocabType \n\t\twhere graphname is an http URI, and vocabType = voc|mdr. Exiting." >> "$logfi
    exit 1
fi
timestamp "metrics for file $filename of type $vocabType vs graph <$graphname>" >> "$logfile"

################################################
# check if logfile exists unnecessary, the rest of the steps would create it
################################################

################################################
# check if data file exists
################################################
if [ ! -f "$dataLoadDir/$filename" ]
then
    timestamp "ERROR: file $filename not found. Exiting." >> "$logfile"
    exit 2
fi

################################################
# check if graph exists in triplestore
################################################
if ! curl -s --request POST "http://127.0.0.1:$sparqlport/sparql/?" --data 'format=text/plain' --data-urlencode 'query=ASK { GRAPH <'"$graphname"'> {?s ?p ?o . } }' | grep -q "true
then
    timestamp "ERROR: <$graphname> doesn't exist in triplestore. Exiting." >> "$logfile"
    exit 2
fi



################################################
# check vocab type and proceed to do metrics comparing DB load to the data file
################################################
if [ "$vocabType" = "owl" ] ; then
    timestamp -n "Test for number of OWL classes " >> "$logfile"
    classes=$(grep -c -E '<owl:Class rdf:about' "$dataLoadDir/$filename")
    queryClass="select (count(?s) as ?count) from <$graphname> where { ?s a owl:Class . filter (isIRI(?s)) }"
    curlRequestC=$(curl -s --request POST "http://localhost:$sparqlport/sparql/?" --data 'format=application/json' --data-urlencode "query=$queryClass")
    if  echo "$curlRequestC" | grep -q -E "\"$classes\"" ; then
                echo ": pass" >> "$logfile"
    else
        echo "ERROR: fail: curl returns $curlRequestC, grep returns $classes"  >> "$logfile"
    fi

    timestamp -n "Test for number of OWL subclasses" >> "$logfile"
    subclass=$(grep -c -E '<rdfs:subClassOf rdf:resource' "$dataLoadDir/$filename")
    querySub="select (count(?s) as ?count) from <$graphname> where { ?s rdfs:subClassOf ?o . filter (isIRI(?o)) }"
    curlRequestS=$(curl -s --request POST "http://localhost:$sparqlport/sparql/?" --data 'format=application/json' --data-urlencode "query=$querySub")
    if  echo "$curlRequestS" | grep -q -E "\"$subclass\"" ; then
        echo ": pass" >> "$logfile"
    else
        echo "ERROR: fail: curl returns $curlRequestS, grep returns $subclass"  >> "$logfile"
    fi
elif [ "$vocabType" = "mdr" ] ; then
    timestamp -n "Test for number of CDE version 1's " >> "$logfile"
    versions=$(grep -c -E '\s+isomdr:version "1"' "$dataLoadDir/$filename")
    queryVersion="prefix isomdr: <http://www.iso.org/11179/MDR#> select (count(?s) as ?count) from <$graphname> where { ?s isomdr:version \"1\" }"
    curlRequestC=$(curl -s --request POST "http://localhost:$sparqlport/sparql/?" --data 'format=application/json' --data-urlencode "query=$queryVersion")
    if  echo "$curlRequestC" | grep -q -E "\"$versions\"" ; then
        echo ": pass" >> "$logfile"
    else
        echo "ERROR: fail: curl returns $curlRequestC, grep returns $versions"  >> "$logfile"
    fi

    timestamp -n "Test for number of CDE permissible values" >> "$logfile"
    PVs=$(grep -c -E '^\s+\[ isomdr:value ' "$dataLoadDir/$filename")
    queryPVs="prefix isomdr: <http://www.iso.org/11179/MDR#> select (count(?s) as ?count) from <$graphname> where { ?s isomdr:value ?o }"
    curlRequestS=$(curl -s --request POST "http://localhost:$sparqlport/sparql/?" --data 'format=application/json' --data-urlencode "query=$queryPVs")
    if  echo "$curlRequestS" | grep -q -E "\"$PVs\"" ; then
        echo ": pass" >> "$logfile"
    else
        echo "ERROR: fail: curl returns $curlRequestS, grep returns $PVs"  >> "$logfile"
    fi
fi

################################################
# end logging
################################################
timestamp "Ending metrics script $0" >> "$logfile"




exit 0 ;

