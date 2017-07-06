#!/bin/bash

echo "phone type (N6P / N5)?"
PHONE_TYPE=""
read -r PHONE_TYPE
#echo "phone type is $PHONE_TYPE"

export DEST_BKP=/home/ludovic/move/bkps_gsms/bkp_${PHONE_TYPE}_$(date "+%d%b%Y")/
echo "*** creating dir for backup: $DEST_BKP"
mkdir "$DEST_BKP"


export SRC_BKP=""
if [ "$PHONE_TYPE" == "N6P" ] 
then
	echo "chosen phone: Nexus 6P"
	#export SRC_BKP="/home/ludovic/move/mount-gsm/Internal shared storage/DCIM/Camera/"
	export SRC_BKP="/home/ludovic/move/mount-gsm/DCIM/Camera/"
elif [ "$PHONE_TYPE" == "N5" ] 
then
	echo "chosen phone: Nexus 5"
	#export SRC_BKP="/home/ludovic/move/mount-gsm/Internal storage/DCIM/Camera/"
	export SRC_BKP="/home/ludovic/move/mount-gsm/DCIM/Camera/"
else 
	echo "unknown phone type entered"
	exit 2
fi

echo
echo "*** mounting phone..."
#this seems like a slower fuse fs#/usr/src/local-builds/android-file-transfer-linux/build/fuse/aft-mtp-mount ~/move/mount-gsm/
simple-mtpfs ~/move/mount-gsm/

echo
echo "*** source dir is ${SRC_BKP}"
cd "${SRC_BKP}"

#from https://serverfault.com/questions/43014/copying-a-large-directory-tree-locally-cp-or-rsync :
echo
echo "*** starting rsync (from dir $(pwd)). this may take a while..."
echo "rsync -aHAXvhW --no-compress --checksum --progress ./*mp4 $DEST_BKP"
rsync -aHAXvhW --no-compress --checksum --progress ./*mp4 "$DEST_BKP"

echo
echo "*** copying done. moving on to file verification"
#TODO can we use xargs here to parallelize stuff? or do we risk messing up the output files?
export SRC_MD5=/tmp/checklist.chk
export BKP_MD5=/tmp/bkp-checklist.chk
echo "*** removing md5sum lists in case they exist..."
rm ${BKP_MD5} ${SRC_MD5}

echo "*** generating md5sum list of source files..."
cd "${SRC_BKP}"
find . -type f -name "*mp4" -exec md5sum "{}" + > ${SRC_MD5}

echo "*** generating md5sum list of bkp files..."
cd "${DEST_BKP}"
find . -type f -name "*mp4" -exec md5sum "{}" + > ${BKP_MD5}

echo
echo "*** sorting & diff'ing md5sum lists..."
sort ${SRC_MD5}  -o ${SRC_MD5}
sort ${BKP_MD5}  -o ${BKP_MD5}
diff ${BKP_MD5} ${SRC_MD5}
echo "md5sum list files are: ${SRC_MD5} ${BKP_MD5}"

echo "*** DON'T FORGET TO REMOVE THE COPIED FILES!"
#TODO - remove source files that were successfully copied

