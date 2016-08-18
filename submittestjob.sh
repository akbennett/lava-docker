#!/bin/bash

tools_path="${tools_path:-/home/lava/bin}"
cd ${tools_path}

echo "Submit v2/pipeline Zephyr qemu-cortex-m3 crypto tests"
./submityaml.py -k apikey.txt job1.yaml
./submityaml.py -k apikey.txt job2.yaml
./submityaml.py -k apikey.txt job3.yaml
./submityaml.py -k apikey.txt job4.yaml
./submityaml.py -k apikey.txt job5.yaml
./submityaml.py -k apikey.txt job6.yaml
./submityaml.py -k apikey.txt job7.yaml
./submityaml.py -k apikey.txt job8.yaml
./submityaml.py -k apikey.txt -p job9.yaml
