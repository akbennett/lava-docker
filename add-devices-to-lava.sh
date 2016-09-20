#!/bin/bash
#Create a qemu devices and add them to lava-server

lava-server manage pipeline-worker --hostname $(hostname)

curdir="$(dirname "$(readlink -f "$0")")"
if [ -f "${curdir}/lava-credentials.txt" ]; then
  . "${curdir}"/lava-credentials.txt
fi

lavaurl=http://localhost
tools_path="${tools_path:-/home/lava/bin}"
hostn=$(hostname)

#obtain the csrf token
data=$(curl -s -c ${tools_path}/cookies.txt $lavaurl/accounts/login/); tail ${tools_path}/cookies.txt

#login
csrf="csrfmiddlewaretoken="$(grep csrftoken ${tools_path}/cookies.txt | cut -d$'\t' -f 7); echo "$csrf"
login=$csrf\&username=$adminuser\&password=$adminpass; echo $login
curl -b ${tools_path}/cookies.txt -c ${tools_path}/cookies.txt -d $login -X POST $lavaurl/admin/login/

mkdir -p /etc/dispatcher-config/devices

COUNTER=1

while [ $COUNTER -lt $1 ]; do
	devicename=qemu-$COUNTER
	devicetype=qemu
	# Add device type
	csrf="csrfmiddlewaretoken="$(cat  ${tools_path}/cookies.txt | grep csrftoken | cut -d$'\t' -f 7)
	createdevicetype=$csrf\&name=$devicetype\&display=on\&health_frequency=24\&_save=Save\&health_denominator=0
	curl -b ${tools_path}/cookies.txt -c ${tools_path}/cookies.txt -d $createdevicetype -X POST $lavaurl/admin/lava_scheduler_app/devicetype/add/
	## Add device
	csrf="csrfmiddlewaretoken="$(cat  ${tools_path}/cookies.txt | grep csrftoken | cut -d$'\t' -f 7)
	createdevice=$csrf\&hostname=$devicename\&device_type=$devicetype\&device_version=1\&status=1\&health_status=0\&is_pipeline="on"\&worker_host=$hostn

	curl -b ${tools_path}/cookies.txt -c ${tools_path}/cookies.txt -d $createdevice -X POST $lavaurl/admin/lava_scheduler_app/device/add/
	lava-server manage device-dictionary --hostname qemu-$COUNTER --import /etc/dispatcher-config/devices/qemu.jinja2
	let COUNTER=COUNTER+1
done
