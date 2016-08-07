#!/bin/bash

tools_path="${tools_path:-/home/lava/bin}"
cd ${tools_path}

echo "Submit basic kvm job for v1 dispatcher device"
submit.py -k apikey.txt kvm-basic.json

echo "Submit basic qemu-aarch64 job for v1 dispatcher device"
submit.py -k apikey.txt kvm-qemu-aarch64.json

echo "Submit and wait for v2/pipeline device to complete"
submityaml.py -k apikey.txt -p qemu.yaml
