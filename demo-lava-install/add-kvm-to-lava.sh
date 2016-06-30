#!/bin/bash
#Create a kvm devicetype and add a kvm device to the lava server

adminuser=admin
adminpass=admin
devicename=kvm01
devicetype=kvm

lavaurl=http://localhost


#obtain the csrf token
data=$(curl -s -c cookies.txt $lavaurl/accounts/login/); tail cookies.txt

#login
csrf="csrfmiddlewaretoken="$(cat cookies.txt | grep csrftoken | cut -d$'\t' -f 7); echo $csrf
login=$csrf\&username=$adminuser\&password=$adminpass; echo $login
curl -b cookies.txt -c cookies.txt -d $login -X POST $lavaurl/admin/login/

# configure device type and device
# Add new device type "kvm"
## http://localhost/admin/lava_scheduler_app/devicetype/add/
csrf="csrfmiddlewaretoken="$(cat cookies.txt | grep csrftoken | cut -d$'\t' -f 7); echo $csrf
createdevicetype=$csrf\&name=$devicetype\&display=on\&health_frequency=24\&_save=Save\&health_denominator=0
curl -b cookies.txt -c cookies.txt -d $createdevicetype -X POST $lavaurl/admin/lava_scheduler_app/devicetype/add/

# Add new device "kvm01" of device type "qemu"
## http://localhost/admin/lava_scheduler_app/device/add/
csrf="csrfmiddlewaretoken="$(cat cookies.txt | grep csrftoken | cut -d$'\t' -f 7); echo $csrf
createdevice=$csrf\&hostname=$devicename\&device_type=$devicetype\&device_version=1\&status=1\&health_status=0
curl -b cookies.txt -c cookies.txt -d $createdevice -X POST $lavaurl/admin/lava_scheduler_app/device/add/

