#!/bin/bash

# Define the list of addresses
addresses=(
"de.zephyr.herominers.com"
"fi.zephyr.herominers.com"
"ca.zephyr.herominers.com"
"ru.zephyr.herominers.com"
"us.zephyr.herominers.com"
"us2.zephyr.herominers.com"
"br.zephyr.herominers.com"
"hk.zephyr.herominers.com"
"kr.zephyr.herominers.com"
"in.zephyr.herominers.com"
"sg.zephyr.herominers.com"
"tr.zephyr.herominers.com"
"au.zephyr.herominers.com"
)
minLatency=1000000
minAddress=""

for address in "${addresses[@]}"
do
    result=$(hping3 --quiet -c 8 -p 1123 -S $address 2>&1 | grep round-trip | awk -F '/' '{print $5}')

    result=${result%.*}

    if [[ ! -z "$result" && "$result" =~ ^[0-9]+$ ]]; then
        echo "$address: $result ms"
        if [ "$result" -lt "$minLatency" ]; then
            minLatency="$result"
            minAddress="$address"
        fi
    else
        echo "No response from $address"
    fi
done

echo "Lowest latency is $minLatency ms at $minAddress"
