#!/bin/bash
#Create a kvm devicetype and add a kvm device to the lava server

adminuser=admin
adminpass=admin

lavaurl=http://localhost


#obtain the csrf token
data=$(curl -s -c cookies.txt $lavaurl/accounts/login/); tail cookies.txt

#login
csrf="csrfmiddlewaretoken="$(cat cookies.txt | grep csrftoken | cut -d$'\t' -f 7); echo $csrf
login=$csrf\&username=$adminuser\&password=$adminpass; echo $login
curl -b cookies.txt -c cookies.txt -d $login -X POST $lavaurl/admin/login/

devicename=kvm01
devicetype=kvm
# add device type
csrf="csrfmiddlewaretoken="$(cat cookies.txt | grep csrftoken | cut -d$'\t' -f 7); echo $csrf
createdevicetype=$csrf\&name=$devicetype\&display=on\&health_frequency=24\&_save=Save\&health_denominator=0
curl -b cookies.txt -c cookies.txt -d $createdevicetype -X POST $lavaurl/admin/lava_scheduler_app/devicetype/add/

# add device
csrf="csrfmiddlewaretoken="$(cat cookies.txt | grep csrftoken | cut -d$'\t' -f 7); echo $csrf
createdevice=$csrf\&hostname=$devicename\&device_type=$devicetype\&device_version=1\&status=1\&health_status=0
curl -b cookies.txt -c cookies.txt -d $createdevice -X POST $lavaurl/admin/lava_scheduler_app/device/add/

devicename=qemu-aarch64-01
devicetype=qemu-aarch64
# add device type
csrf="csrfmiddlewaretoken="$(cat cookies.txt | grep csrftoken | cut -d$'\t' -f 7); echo $csrf
createdevicetype=$csrf\&name=$devicetype\&display=on\&health_frequency=24\&_save=Save\&health_denominator=0
curl -b cookies.txt -c cookies.txt -d $createdevicetype -X POST $lavaurl/admin/lava_scheduler_app/devicetype/add/

## Add device
csrf="csrfmiddlewaretoken="$(cat cookies.txt | grep csrftoken | cut -d$'\t' -f 7); echo $csrf
createdevice=$csrf\&hostname=$devicename\&device_type=$devicetype\&device_version=1\&status=1\&health_status=0
curl -b cookies.txt -c cookies.txt -d $createdevice -X POST $lavaurl/admin/lava_scheduler_app/device/add/

