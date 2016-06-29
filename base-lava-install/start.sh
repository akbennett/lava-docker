#!/bin/bash

postgres-ready () {
  echo "Waiting for lavaserver database to be active"
  while (( $(ps -ef | grep -v grep | grep postgres | grep lavaserver | wc -l) == 0 ))
  do
    echo -n "."
    sleep 1
  done
  echo 
  echo "[ ok ] LAVA server ready"
}

start () {
  echo "Starting $1"
  if (( $(ps -ef | grep -v grep | grep $1 | wc -l) > 0 ))
  then
    echo "$1 appears to be running"
  else
    service $1 start
  fi
}

start postgresql
start apache2
start lava-server

postgres-ready
