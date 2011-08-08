#!/bin/bash 
#SMCS: Sarven's Magical Collection of Scripts for DIP: Data Ingestion Pipeline
#Usage: dip.sh voidurl e.g., dip.sh http://example.org/void.ttl
#Make sure that uncompress.sh is in the same directory as this script.

#Config
#Location to store the dumps
basedir='/var/www/data-gov.ie/data'
#dataset name that is used in Fuseki where we import our data
dataset='dataset'
#port number in which we are running the Fuseki server
port='3131'

if [ $# -eq 0 -o "$1" = "-h" -o "$1" = "--h" -o "$1" = "-help" -o "$1" = "--help" ]
   then
       echo "Usage: dip.sh voidurl"
       echo "       example: dip.sh http://example.org/void.ttl"
       exit 1
else
   voidurl=$1
fi

voidurlsafe=`echo -n "$voidurl" | perl -pe 's/[^a-zA-Z0-9\._-]/_/g'`
voiddir="$basedir/$voidurlsafe"

mkdir "$voiddir"
voidfile="$voiddir/void.ntriples"

rapper -g "$voidurl" -o ntriples > "$voidfile"

#XXX: Ideally we should see what the bnode has to say for the dataDump, but, this should suffice. No need to have a bnode there any way.
ddu=`grep -E "[^ ]* <http://rdfs.org/ns/void#dataDump> [^ ]* ." $voidfile | perl -pe 's/([^ ]*) \<http\:\/\/rdfs\.org\/ns\/void\#dataDump\> \<?([^ >]*)\>? \./$2/'`

#datadumpurlMD5=`echo -n $datadumpurl|md5sum|cut -f1 -d" "`

for datadumpurl in $( echo -e "$ddu" );
    do
        echo $datadumpurl
        datadumpfilesafe=`echo -n "$datadumpurl" | perl -pe 's/[^a-zA-Z0-9\.-]/_/g'`

        datadumpfile="$voiddir/$datadumpfilesafe"

        wget -O - "$datadumpurl" > "$datadumpfile"
        #wget $datadumpurl --directory-prefix=$TARGETDIR

        filetype=`file "$datadumpfile"`
        case "$filetype" in
            "$datadumpfile: gzip compressed"* | "$datadumpfile: bzip2 compressed"* | "$datadumpfile: compress"* | "$datadumpfile: Zip archive"* | "$datadumpfile: 7-zip archive"* | "$datadumpfile: RAR archive"*)
                ./uncompress.sh "$datadumpfile" "$voiddir"
                ;;
            *)
                echo "dataDump is not compressed. We should have our RDF triples already."
                ;;
        esac
    done


for file in "$voiddir"/*.ttl;
    do
        /usr/lib/fuseki/./s-post --verbose http://localhost:"$port"/"$dataset"/data "$voidurl" "$file";
    done;

