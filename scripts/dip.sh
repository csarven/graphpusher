#!/bin/bash 
#SMCS: Sarven's Magical Collection of Scripts for DIP: Data Ingestion Pipeline
#Usage: dip.sh voidURL e.g., dip.sh http://example.org/void.ttl
#Make sure that uncompress.sh is in the same directory as this script.

#Config
#Location to store the dumps
BASEDIR='/var/www/datadumps'
#Dataset name that is used in Fuseki where we import our data
DATASET='dataset'
#Port number in which we are running the Fuseki server
PORT='3030'

if [ $# -eq 0 -o "$1" = "-h" -o "$1" = "--h" -o "$1" = "-help" -o "$1" = "--help" ]
   then
       echo "Usage: dip.sh voidURL"
       echo "       example: dip.sh http://example.org/void.ttl"
       exit 1
else
   VOIDURL=$1
fi

VOIDDIR=`echo -n $VOIDURL | perl -pe 's/[^a-zA-Z0-9\._-]/_/g'`
VOIDDIR="$BASEDIR/$VOIDDIR"

mkdir $VOIDDIR
VOIDFILE="$VOIDDIR/void.ntriples"

rapper -g $VOIDURL -o ntriples > $VOIDFILE

#XXX: Ideally we should see what the bnode has to say for the dataDump, but, this should suffice. No need to have a bnode there any way.
DATADUMPURL=`grep -E "[^ ]* <http://rdfs.org/ns/void#dataDump> [^ ]* ." $VOIDFILE | perl -pe 's/([^ ]*) \<http\:\/\/rdfs\.org\/ns\/void\#dataDump\> \<?([^ >]*)\>? \./$2/'`

#TODO: Iterate (wget) through all dataDump URLs here

#DATADUMPURLMD5=`echo -n $DATADUMPURL|md5sum|cut -f1 -d" "`
DATADUMPFILESAFE=`echo -n $DATADUMPURL | perl -pe 's/[^a-zA-Z0-9\.-]/_/g'`

DATADUMPFILE="$VOIDDIR/$DATADUMPFILESAFE"


wget -O - $DATADUMPURL > $DATADUMPFILE
#wget $DATADUMPURL --directory-prefix=$TARGETDIR

FILETYPE=`file $DATADUMPFILE`
echo $FILETYPE
case $FILETYPE in
    "$DATADUMPFILE: gzip compressed"* | "$DATADUMPFILE: bzip2 compressed"* | "$DATADUMPFILE: compress"* | "$DATADUMPFILE: Zip archive"* | "$DATADUMPFILE: 7-zip archive"* | "$DATADUMPFILE: RAR archive"*)
        ./uncompress.sh $DATADUMPFILE $VOIDDIR
        ;;
    *)
        echo "dataDump is not compressed. We should have our RDF triples already."
        ;;
esac

for file in $VOIDDIR/*.ttl;
    do
        /usr/lib/fuseki/./s-post --verbose http://localhost:$PORT/$DATASET/data $DATADUMPURL $file;
    done;
