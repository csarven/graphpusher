#!/bin/bash 
#SMCS: Sarven's Magical Collection of Scripts for DIP: Data Ingestion Pipeline
#Usage: dip.sh voidurl e.g., dip.sh http://example.org/void.ttl
#Make sure that uncompress.sh is in the same directory as this script.

#Config
#Location to store the dumps
basedir='/var/www/test'
#dataset name that is used in Fuseki where we import our data
dataset='cso'
#port number in which we are running the Fuseki server
port='3030'

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
voidfile="$voiddir/void.nt"

rapper -g "$voidurl" -o ntriples > "$voidfile"

#XXX: Ideally we should see what the bnode has to say for the dataDump, but, this should suffice. No need to have a bnode there any way.
ddu=`grep -E "[^ ]* <http://rdfs.org/ns/void#dataDump> [^ ]* ." "$voidfile" | perl -pe 's/([^ ]*) \<http\:\/\/rdfs\.org\/ns\/void\#dataDump\> \<?([^ >]*)\>? \./$2/'`

#datadumpurlMD5=`echo -n $datadumpurl|md5sum|cut -f1 -d" "`

for datadumpurl in $( echo -e "$ddu" );
    do
#        echo $datadumpurl
        datadumpfilesafe=`echo -n "$datadumpurl" | perl -pe 's/[^a-zA-Z0-9\._-]/_/g'`

        datadumpfile="$voiddir/$datadumpfilesafe"

        wget -O - "$datadumpurl" > "$datadumpfile"

        filetype=`file "$datadumpfile"`
        case "$filetype" in
            "$datadumpfile: gzip compressed"* | "$datadumpfile: bzip2 compressed"* | "$datadumpfile: compress"* | "$datadumpfile: Zip archive"* | "$datadumpfile: 7-zip archive"* | "$datadumpfile: RAR archive"*)
                ./uncompress.sh "$datadumpfile" "$voiddir"
                ;;
            *)
                echo "XXX: dataDump is not compressed. This is okay for now. We'll check later to really make sure it is one of the RDF formats"
                ;;
        esac
    done

for file in "$voiddir"/*;
    do
        filename=$(basename $file);
        extension=${filename##*.};
#        echo "$extension";
        #TODO: Refactor to use only RDF files instead. Probably need to do rapper earlier.
        if [[ "$filename" != "void.nt" && "$extension" != "gz" && "$extension" != "tar.gz" && "$extension" != "bz2" && "$extension" != "bz" && "$extension" != "tar.bz" && "$extension" != "Z" && "$extension" != "tgz" && "$extension" != "tar.tgz" && "$extension" != "zip" && "$extension" != "rar" && "$extension" != "7z" ]]
            then
                #We reserialize because Fuseki needs to know the filetype for HTTP.
                rapper -g "$file" -o turtle > "$file".ttl

                /usr/lib/fuseki/./s-put --verbose http://localhost:"$port"/"$dataset"/data "$voidurl" "$file".ttl
                rm "$file".ttl
        fi
    done;
