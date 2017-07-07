#!/bin/bash

echo "phone type (N6P / N5)?"
PHONE_TYPE=""
read -r PHONE_TYPE
#echo "phone type is $PHONE_TYPE"

FILES_TO_BKP="*.mp4"
export FILES_TO_BKP="*.mp4"

MOUNT_DIR="${HOME}/move/mount-gsm/"
export MOUNT_DIR

DEST_BKP=${HOME}/move/bkps_gsms/bkp_${PHONE_TYPE}_$(date "+%d%b%Y")/
export DEST_BKP
echo "*** creating dir for backup: $DEST_BKP"
mkdir "$DEST_BKP"


export SRC_BKP=""
if [ "$PHONE_TYPE" == "N6P" ] 
then
	echo "chosen phone: Nexus 6P"
	export SRC_BKP="${MOUNT_DIR}/Internal shared storage/DCIM/Camera/"
	#export SRC_BKP="${MOUNT_DIR}/DCIM/Camera/"
elif [ "$PHONE_TYPE" == "N5" ] 
then
	echo "chosen phone: Nexus 5"
	#export SRC_BKP="${MOUNT_DIR}/DCIM/Camera/"
	export SRC_BKP="${MOUNT_DIR}/Internal storage/DCIM/Camera/"
else 
	echo "unknown phone type entered"
	exit 2
fi

echo
echo "*** mounting phone..."
aft-mtp-mount "${MOUNT_DIR}"
#simple-mtpfs "${MOUNT_DIR}"

echo
echo "*** source dir is ${SRC_BKP}"


SPLIT_DIR="/tmp/split_output/"
export SPLIT_DIR
mkdir "$SPLIT_DIR"
echo
echo "*** building lists of files to rsync..."
cd "$SPLIT_DIR" || exit 9
find . -type f -iname "$FILES_TO_BKP" | split -l 20


echo "*** starting rsync (from dir $(pwd)). this may take a while..."
echo "rsync -aHAXvhW --no-compress --checksum --progress $FILES_TO_BKP $DEST_BKP"
#from https://serverfault.com/questions/43014/copying-a-large-directory-tree-locally-cp-or-rsync :
for BATCH in "${SPLIT_DIR}"*; 
	do rsync -aHAXvhW --no-compress --checksum --progress --files-from="$BATCH" "${SRC_BKP}" "$DEST_BKP"; 
done
###rsync -aHAXvhW --no-compress --checksum --progress "$FILES_TO_BKP" "$DEST_BKP"
#TODO uncomment#rm -rf "$SPLIT_DIR"

echo
echo "*** copying done. moving on to file verification"
#TODO can we use xargs or GNU Parallel here to parallelize stuff? or do we risk messing up the output files?
export SRC_MD5=/tmp/checklist.chk
export BKP_MD5=/tmp/bkp-checklist.chk
echo "*** removing md5sum lists in case they exist..."
rm ${BKP_MD5} ${SRC_MD5}

echo "*** generating md5sum list of source files..."
cd "${SRC_BKP}"
find . -type f -name "$FILES_TO_BKP" -exec md5sum "{}" + > ${SRC_MD5}

echo "*** generating md5sum list of bkp files..."
cd "${DEST_BKP}"
find . -type f -name "$FILES_TO_BKP" -exec md5sum "{}" + > ${BKP_MD5}

echo
echo "*** sorting & diff'ing md5sum lists..."
sort ${SRC_MD5} -o ${SRC_MD5}
sort ${BKP_MD5} -o ${BKP_MD5}
diff ${BKP_MD5} ${SRC_MD5}
echo "md5sum list files are: ${SRC_MD5} ${BKP_MD5}"

echo "*** DON'T FORGET TO REMOVE THE COPIED FILES!"
#TODO - remove source files that were successfully copied

