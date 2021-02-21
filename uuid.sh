#!/bin/bash

# autogen UUID
uuid1=$(cat /proc/sys/kernel/random/uuid)
uuid2=$(cat /proc/sys/kernel/random/uuid | sed 's/-//g')

echo "Random UUID-1: "$uuid1
echo "Random UUID-2: "$uuid2


