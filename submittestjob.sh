#!/bin/bash
echo "Submit basic kvm job for v1 dispatcher device"
/tools/submit.py -k /apikey.txt /tools/kvm-basic.json
echo "Submit basic qemu-aarch64 job for v1 dispatcher device"
/tools/submit.py -k /apikey.txt /tools/kvm-qemu-aarch64.json

#submit a pipeline job
echo "Submit and wait for v2/pipeline device to complete"
/tools/submityaml.py -k /apikey.txt -p /tools/qemu.yaml
