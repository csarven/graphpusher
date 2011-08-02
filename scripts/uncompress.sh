#!/bin/sh
#XXX: From http://code.google.com/p/shell-learning/source/browse/trunk/bash/uncompress.sh
#Slightly modified to extract the files into target directory. - Sarven Capadisli

#uncompress.sh is to uncompress the FileName{.gz,.tar.gz, .bz2,.bz,
#.tar.bz,.Z,.tgz,.tar.tgz,.zip,.rar,.7z}files to FileName Directory
#
#
#
if [ $# -eq 0 -o "$1" = "-h" -o "$1" = "--h" ]
   then
       echo "Usage: uncompress.sh compressfile target"
       echo "       example: smaruncompress.sh /home/yorks/test.tar.gz /home/yorks/test/"
       exit 1
fi
if [ "$2" = "" ]
   then
      target=`pwd`
else
   target=$2
fi
mkdir -p $target
FILETYPE=`file $1`
FILENAME=`basename $1`
FILECOPY=$target"/"$FILENAME
case $FILETYPE in
     $1": gzip compressed data"*)     #gzip files i.e.: .gz,.tgz, tar.gz, tar.tgz
         if [ `basename $1 .tar.gz` != $FILENAME -o `basename $1 .tar.tgz` != $FILENAME ]
              then
                  echo "is a tar packget"
                  tar zxvf $1 -C $target --overwrite
         elif [ `basename $1 .tgz` != $FILENAME ]
              then
                  echo "Uncompressing .tgz file"
                  tar zxvf $1 -C $target --overwrite
         else
             echo "Uncompressing .gz file"
             if [ "$2" = "" ]
                then
                   cp $1 $qtarget"/"$FILENAME".back" #backup the original file
                   echo "$1 have backup TO $target"/"$FILENAME".back""
             fi
             gzip -f -d $FILECOPY
         fi
         ;;
     $1': bzip2 compressed data'*)  #bzip2 files i.e.: .bz2, tar.bz2
         if [ `basename $1 .tar.bz2` != $FILENAME ]
         then
            echo "is a bz2 tar packget"
            tar jxvf $1 -C $target --overwrite
         else
            echo "is not a tar packget"
             if [ "$2" = "" ]
                then
                   cp $1 $target"/"$FILENAME".back" #backup the original file
                   echo "$1 have backup TO $target"/"$FILENAME".back""
             fi
            bzip2 -f -d $FILECOPY
         fi
         ;;
     $1": compress'd data"*)  #.Z, tar.Z files
        if [ `basename $1 .tar.Z` != $1 ]
        then
           echo "is a tar packget"
           tar Zxvf $1 -C $target
        else
           echo "is not a tar packget"
             if [ "$2" = "" ]
                then
                   cp $1 $target"/"$FILENAME".back" #backup the original file
                   echo "$1 have backup TO $target"/"$FILENAME".back""
             fi
           uncompress $FILECOPY
        fi
        ;;
     $1": Zip archive data"*) #.zip file
        echo "Uncompresing .zip file"
        if [ "$2" = "" ]
           then
               cp $1 $target"/"$FILENAME".back" #backup the original file
               echo "$1 have backup TO $target"/"$FILENAME".back""
        fi
        unzip -o $FILECOPY -d $target
        ;;
     $1": 7-zip archive data"*) # .7z file
        echo "Uncompresing .7-zip file"
        if [ "$2" = "" ]
           then
               cp $1 $target"/"$FILENAME".back" #backup the original file
               echo "$1 have backup TO $target"/"$FILENAME".back""
        fi
        7za x $FILECOPY -o$target
        ;;
     $1": RAR archive data"*) #.rar file
        if [ "$2" = "" ]
           then
              cp $1 $target"/"$FILENAME".back" #backup the original file
              echo "$1 have backup TO $target"/"$FILENAME".back""
        fi
        rar -o+ x $FILECOPY $target
        ;;
     *)
      echo "please use a compress file!"
      exit 1
      ;;
esac

