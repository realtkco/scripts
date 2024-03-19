#!/bin/bash

# List of server addresses
servers=(
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

port=1123

# Variables to keep track of the server with the lowest latency
minLatency=1000000
minServer=""

for server in "${servers[@]}"; do
    echo "Pinging $server..."

    # Run paping, extract average latency
    result=$(paping "$server" -c 3 -p $port | grep 'Average' || echo "Error pinging $server")

    # Check if paping encountered an error
    if [[ $result == *"Error pinging"* ]]; then
        echo $result
        continue
    fi

    # Extract the average latency, removing ANSI color codes and any illegal characters
    latency=$(echo $result | sed 's/\x1b\[[0-9;]*m//g' | awk -F' ' '{ for(i=1;i<=NF;i++) if ($i=="Average") print $(i+2) }' | sed 's/ms//' | tr -d '[:cntrl:]')

    if [[ -z $latency ]]; then
        echo "Failed to extract latency for $server."
        continue
    fi

    echo "Average latency for $server: $latency ms"

    # Use bc for comparison, ensuring input is properly formatted
    comparison=$(echo "$latency < $minLatency" | bc 2>/dev/null)

    if [[ $comparison -eq 1 ]]; then
        minLatency=$latency
        minServer=$server
    fi
done

echo "The server with the lowest latency is $minServer with an average latency of $minLatency ms."
