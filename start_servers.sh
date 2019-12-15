#!/bin/bash

for (( i=1; i<=30; i++ ))
do
    export ORACLE_INDEX=$i
    node ./src/server/server.js &
    echo "started server: $i"
    sleep 1
done
