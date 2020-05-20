#!/bin/bash
#remove empty space from .img,iso, etc

C='\033[1;36m'
R='\033[1;31m'
Y='\033[1;33m'
NC='\033[0m'

verifyPack () {
	ISTHERE=$(dpkg -s $PROG |grep Status)
	OK="Status: install ok installed"
	if [ "$ISTHERE" = "$OK" ]; then echo "${C}$PROG is already installed :)${NC}"
	else 
		echo "${C}Will install $PROG${NC}"
		sudo apt install -y --install-recommends $PROG
		ISTHERE=$(dpkg -s $PROG |grep Status)
		if [ "$ISTHERE" = "$OK" ]; then echo "${C}$PROG installed successfully :)!${NC}"
		else echo "${R}Wasn't able to install $PROG :(${NC}"
		fi
	fi
}


getNumOfPartitions () {
	RES=""
	N=0
	while [ -z "$RES" ]
	do
		N=$(($N + 1))
		RES=$(sudo fdisk -l $FREELOOP | tail -$N | grep Device)
		RES="$RES"	
	done

	PARTNUM=$(($N - 1))
	#echo "Device has $PARTNUM partitions"
}

getLastPartData () {
	sudo fdisk -l $FREELOOP | tail -$(($N - $PARTNUM)) ## data for last partition
}

getPartStart () {
	OUT=$(sudo fdisk -l $FREELOOP | tail -$(($N - $PARTNUM)) | awk '{print$2}')	
}

getPartEnd () {
	OUT=$(sudo fdisk -l $FREELOOP | tail -$(($N - $PARTNUM)) | awk '{print$3}')
}
getSectorSz () {
	SECTORSZ=$(sudo fdisk -l $FREELOOP |grep Sector\ size | awk 'END {print $(NF-1), $NF}' | tr -dc '0-9')
}


#echo -n "Which pack to verify: ";read PROG
PROG="fdisk"
verifyPack $PROG 
PROG="util-linux"
verifyPack $PROG
PROG="subversion"
verifyPack $PROG  

sudo modprobe loop && echo "Enabled loopback :)"
FREELOOP=$(sudo losetup -f)

cd /home/matias/Desktop
echo -n "In: "; pwd
echo ".img files:"
ls -l |grep .img
echo -n "Select img file to mount: ";read IMG
echo "Will mount to: $FREELOOP"
sudo losetup $FREELOOP $IMG && echo "$IMG mounted to $FREELOOP"
sudo partprobe $FREELOOP

getNumOfPartitions FREELOOP
echo "Image has $PARTNUM partitions"
echo "${C}Verify image data: ${NC}"
sudo fdisk -l $FREELOOP
echo "${C}Data for last parition:${NC}"
getLastPartData
getPartEnd FREELOOP
echo "${C}Last partition ends in sector ${NC}$OUT "


OSZ=$(ls -l --block-size=G |grep $IMG | awk '{print$5}')
echo -n "Press Enter if all is correct"; read keyPress
if [ -z $keyPress ] 
	then 
	echo "${C}Will truncate image...${NC}" 
	OUT=$(($OUT + 1))
	getSectorSz FREELOOP
	TRUNC=$(($OUT * $SECTORSZ))
	truncate --size=$TRUNC $IMG
	CSZ=$(ls -l --block-size=G |grep $IMG | awk '{print$5}')
	echo "${C}Truncated $IMG from $OSZ to $CSZ${NC} "	
	else echo "${C}Ard${NC}"
fi
#truncate --size=$[($OUT+1)*$SECTORSZ] $IMG	





