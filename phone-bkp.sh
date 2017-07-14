#!/bin/bash

PHONE_TYPE=""
while [ "${PHONE_TYPE}" != "N6P" ] && [ "${PHONE_TYPE}" != "N5" ]
do 
	echo "phone type (N6P / N5)?"
	read -r PHONE_TYPE
done
#echo "phone type is $PHONE_TYPE"

FILES_TO_BKP="*.mp4"
export FILES_TO_BKP

MOUNT_DIR="${HOME}/move/mount-gsm/"
export MOUNT_DIR

DEST_DIR=${HOME}/move/bkps_gsms/bkp_${PHONE_TYPE}_$(date "+%d%b%Y")/
export DEST_DIR
echo "*** creating dir for backup: $DEST_DIR"
mkdir "$DEST_DIR"


echo -e "\n*** mounting phone at ${MOUNT_DIR}..."
aft-mtp-mount "${MOUNT_DIR}"
#simple-mtpfs "${MOUNT_DIR}"


export SRC_DIR=""
if [ "$PHONE_TYPE" == "N6P" ] 
then
	echo "chosen phone: Nexus 6P"
	export SRC_DIR="${MOUNT_DIR}Internal shared storage/DCIM/Camera/"
	#export SRC_DIR="${MOUNT_DIR}DCIM/Camera/"
elif [ "$PHONE_TYPE" == "N5" ] 
then
	echo "chosen phone: Nexus 5"
	#export SRC_DIR="${MOUNT_DIR}DCIM/Camera/"
	export SRC_DIR="${MOUNT_DIR}Internal storage/DCIM/Camera/"
else 
	echo "unknown phone type entered"
	exit 2
fi
echo -e "\n*** source dir is ${SRC_DIR}"


SPLIT_DIR="/tmp/split_output/"
export SPLIT_DIR
SIZE_OF_SPLITS=20
export SIZE_OF_SPLITS
mkdir "${SPLIT_DIR}"
echo -e "\n*** removing files in ${SPLIT_DIR}, if any..."
echo FIXME rm "${SPLIT_DIR}"*
echo
echo "*** building lists of files to rsync..."
cd "${SPLIT_DIR}" || exit 9
find "${SRC_DIR}" -type f -iname "$FILES_TO_BKP" | split -l ${SIZE_OF_SPLITS}

echo -e "\n*** modifying find results to have a relative path..."
for split_file in "${SPLIT_DIR}"* ; 
do 
	while read -r FILE_PATH; 
		do realpath --relative-base="${SRC_DIR}" "$FILE_PATH" >> "${split_file}_relative"; 
	done < "${split_file}"; 
done


echo -e "\n*** starting rsync (from dir $(pwd)). this may take a while..."
#from https://serverfault.com/questions/43014/copying-a-large-directory-tree-locally-cp-or-rsync :
for BATCH in "${SPLIT_DIR}"*_relative; 
	do echo rsync -aHAXvhW --no-compress --checksum --progress --files-from="$BATCH" "${SRC_DIR}" "$DEST_DIR"; 
	#rsync -aHAXvhW --no-compress --checksum --progress --files-from="$BATCH" / "$DEST_DIR"; 
	rsync -aHAXvhW --no-compress --checksum --progress --files-from="$BATCH" "${SRC_DIR}" "$DEST_DIR"; 
done
###echo "rsync -aHAXvhW --no-compress --checksum --progress $FILES_TO_BKP $DEST_DIR"
###rsync -aHAXvhW --no-compress --checksum --progress "$FILES_TO_BKP" "$DEST_DIR"

echo
echo -e "\n*** copying done. moving on to file verification"
#TODO can we use xargs or GNU Parallel here to parallelize stuff? or do we risk messing up the output files?
export SRC_MD5=/tmp/checklist.chk
export BKP_MD5=/tmp/bkp-checklist.chk
echo "*** removing md5sum lists in case they exist..."
rm ${BKP_MD5} ${SRC_MD5}

echo "*** generating md5sums of source files..."
cd "${SRC_DIR}"
find . -type f -name "$FILES_TO_BKP" -exec md5sum "{}" + > ${SRC_MD5}

echo "*** generating md5sums of bkp files..."
cd "${DEST_DIR}"
find . -type f -name "$FILES_TO_BKP" -exec md5sum "{}" + > ${BKP_MD5}

echo
echo "*** sorting & diff'ing md5sum lists..."
sort ${SRC_MD5} -o ${SRC_MD5}
sort ${BKP_MD5} -o ${BKP_MD5}
diff ${BKP_MD5} ${SRC_MD5}
echo "md5sum list files are: ${SRC_MD5} ${BKP_MD5}"

echo "*** DON'T FORGET TO REMOVE THE COPIED FILES!"
#TODO - remove source files that were successfully copied

