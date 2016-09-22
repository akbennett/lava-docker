#!/bin/bash
#Create kvm (LAVA v1) devices and add them to lava-server

curdir="$(dirname "$(readlink -f "$0")")"
if [ -f "${curdir}/lava-credentials.txt" ]; then
  . "${curdir}"/lava-credentials.txt
fi

lavaurl=http://localhost
tools_path="${tools_path:-/home/lava/bin}"
hostn=$(hostname)

#obtain the csrf token
data=$(curl -s -c ${tools_path}/cookies.txt $lavaurl/accounts/login/); 
#DEBUG tail ${tools_path}/cookies.txt

#login
csrf="csrfmiddlewaretoken="$(grep csrftoken ${tools_path}/cookies.txt | cut -d$'\t' -f 7);
#DEBUG echo "$csrf"
login=$csrf\&username=$adminuser\&password=$adminpass;
#DEBUG echo $login
curl -b ${tools_path}/cookies.txt -c ${tools_path}/cookies.txt -d $login -X POST $lavaurl/admin/login/ > /dev/null

mkdir -p /etc/dispatcher-config/devices


#Add the device type
devicetype=kvm
csrf="csrfmiddlewaretoken="$(grep csrftoken ${tools_path}/cookies.txt | cut -d$'\t' -f 7);
#DEBUG echo "$csrf"
createdevicetype=$csrf\&name=$devicetype\&display=on\&health_frequency=24\&_save=Save\&health_denominator=0
curl -b ${tools_path}/cookies.txt -c ${tools_path}/cookies.txt -d $createdevicetype -X POST $lavaurl/admin/lava_scheduler_app/devicetype/add/ > /dev/null

COUNTER=1

#add multiple devices
while [ $COUNTER -le $1 ]; do
	devicename=kvm-$COUNTER
	csrf="csrfmiddlewaretoken="$(grep csrftoken ${tools_path}/cookies.txt | cut -d$'\t' -f 7);
        #DEBUG echo "$csrf"
	createdevice=$csrf\&hostname=$devicename\&device_type=$devicetype\&device_version=1\&status=1\&health_status=0\&worker_host=$hostn
	curl -b ${tools_path}/cookies.txt -c ${tools_path}/cookies.txt -d $createdevice -X POST $lavaurl/admin/lava_scheduler_app/device/add/ > /dev/null
        /usr/share/lava-server/add_device.py kvm $devicename 
        echo "root_part=1" >> /etc/lava-dispatcher/devices/$devicename.conf
        let COUNTER=COUNTER+1
done

