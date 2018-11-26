#!/bin/bash
# Get base packages up-to-date.
apt update -y && apt dist-upgrade -y && apt autoremove -y
# Install what we needs
apt install shadowsocks-libev simple-obfs haveged curl -y
# Enable haveged for more entropy on cloud server
systemctl enable haveged.service && systemctl restart haveged.service
# Backup /etc/sysctl.conf
mv /etc/sysctl.conf /etc/sysctl.conf.orig
# Write optimized kernel parameters 
cat > /etc/sysctl.conf <<END
# Enable BBR TCP Congestion Control.
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

# The maximum size of the receive queue.
# The received frames will be stored in this queue after taking them
# from the ring buffer on the NIC.
# Use high value for high speed cards to prevent loosing packets.
# In real time application like SIP router, long queue must be assigned
# with high speed CPU otherwise the data in the queue will be out of
# date (old).
net.core.netdev_max_backlog = 65536

# The maximum ancillary buffer size allowed per socket.
# Ancillary data is a sequence of struct cmsghdr structures with
# appended data.
net.core.optmem_max = 65536

# The upper limit on the value of the backlog parameter passed to the
# listen function.
# Setting to higher values is only needed on a single highloaded server
# where new connection rate is high/bursty
net.core.somaxconn = 16384

# The default and maximum amount for the receive/send socket memory
# By default the Linux network stack is not configured for high speed
# large file transfer across WAN links.
# This is done to save memory resources.
# You can easily tune Linux network stack by increasing network buffers
# size for high-speed networks that connect server systems to handle more network packets.
net.core.rmem_default = 1048576
net.core.wmem_default = 1048576
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.udp_rmem_min = 16384
net.ipv4.udp_wmem_min = 16384

# An extension to the transmission control protocol (TCP) that helps
# reduce network latency by enabling data to be exchanged during the
# sender’s initial TCP SYN.
# If both of your server and client are deployed on Linux 3.7.1 or
# higher, you can turn on fast_open for lower latency
net.ipv4.tcp_fastopen = 3

# The maximum queue length of pending connections 'Waiting
# Acknowledgment'
# In the event of a synflood DOS attack, this queue can fill up pretty
# quickly, at which point tcp_syncookies will kick in allowing your
# system to continue to respond to legitimate traffic, and allowing you
# to gain access to block malicious IPs.
# If the server suffers from overloads at peak times, you may want to
# increase this value a little bit.
net.ipv4.tcp_max_syn_backlog = 65536

# The maximum number of sockets in 'TIME_WAIT' state.
# After reaching this number the system will start destroying the
# socket in this state.
# Increase this to prevent simple DOS attacks
net.ipv4.tcp_max_tw_buckets = 65536

# Whether TCP should start at the default window size only for new
# connections or also for existing connections that have been idle for
# too long.
# It kills persistent single connection performance and should be turned
# off.
net.ipv4.tcp_slow_start_after_idle = 0

# Whether TCP should reuse an existing connection in the TIME-WAIT state
# for a new outgoing connection if the new timestamp is strictly bigger
# than the most recent timestamp recorded for the previous connection.
# This helps avoid from running out of available network sockets.
net.ipv4.tcp_tw_reuse = 1

# Fast-fail FIN connections which are useless.
net.ipv4.tcp_fin_timeout = 15

# TCP keepalive is a mechanism for TCP connections that help to
# determine whether the other end has stopped responding or not.
# TCP will send the keepalive probe contains null data to the network
# peer several times after a period of idle time. If the peer does not
# respond, the socket will be closed automatically.
# By default, TCP keepalive process waits for two hours (7200 secs) for
# socket activity before sending the first keepalive probe, and then
# resend it every 75 seconds. As long as there is TCP/IP socket
# communications going on and active, no keepalive packets are needed.
# With the following settings, your application will detect dead TCP
# connections after 120 seconds (60s + 10s + 10s + 10s + 10s + 10s +
# 10s)
net.ipv4.tcp_keepalive_time = 60
net.ipv4.tcp_keepalive_intvl = 10
net.ipv4.tcp_keepalive_probes = 6

# The longer the MTU the better for performance, but the worse for
# reliability.
# This is because a lost packet means more data to be retransmitted
# and because many routers on the Internet can't deliver very long
# packets.
# Enable smart MTU discovery when an ICMP black hole detected.
net.ipv4.tcp_mtu_probing = 1

# Turn timestamps off to reduce performance spikes related to timestamp
# generation.
net.ipv4.tcp_timestamps = 0

# Max open files.
fs.file-max = 65536

# Turn off fast timewait sockets recycling.
# net.ipv4.tcp_tw_recycle = 0 # Deprecated

# Outbound port range
net.ipv4.ip_local_port_range = 10000 65000


## TCP SYN cookie protection (default)
## helps protect against SYN flood attacks
## only kicks in when net.ipv4.tcp_max_syn_backlog is reached
net.ipv4.tcp_syncookies = 1

## protect against tcp time-wait assassination hazards
## drop RST packets for sockets in the time-wait state
## (not widely supported outside of linux, but conforms to RFC)
net.ipv4.tcp_rfc1337 = 1

## sets the kernels reverse path filtering mechanism to value 1 (on)
## will do source validation of the packet's recieved from all the interfaces on the machine
## protects from attackers that are using ip spoofing methods to do harm
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.rp_filter = 1

## log martian packets
net.ipv4.conf.default.log_martians = 1
net.ipv4.conf.all.log_martians = 1

## ignore echo broadcast requests to prevent being part of smurf attacks (default)
net.ipv4.icmp_echo_ignore_broadcasts = 1

## ignore bogus icmp errors (default)
net.ipv4.icmp_ignore_bogus_error_responses = 1

## send redirects (not a router, disable it)
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.send_redirects = 0

## ICMP routing redirects (only secure)
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0

# Restricting access to kernel logs.
kernel.dmesg_restrict = 1
# Restricting access to kernel pointers in the proc filesystem.
kernel.kptr_restrict = 1
END
# Enable our kernel parameters.
sysctl -p
# Generate password. /dev/random is safer than /dev/urandom
PASSWORD=$(cat /dev/random | tr -dc 'a-zA-Z0-9+/' | fold -w 48 | head -n 1)
# Write Shadowsocks config file.
cat > /etc/shadowsocks-libev/config.json <<END
{
    "server":["::", "0.0.0.0"],
    "server_port":443,
    "method": "aes-256-gcm",
    "password": "$PASSWORD",
    "timeout": 60,
    "mode":"tcp_and_udp",
    "plugin":"obfs-server",
    "plugin_opts":"obfs=tls"
}
END
# Enable Shadowsocks service.
systemctl enable shadowsocks-libev.service && systemctl restart shadowsocks-libev.service
# Get server's public IP.
SERVER_IP=$(curl https://ipecho.net/plain)
# Write client config.
cat > ~/client.json <<END
{
    "server": "$SERVER_IP",
    "server_port": 443,
    "method": "aes-256-gcm",
    "password": "$PASSWORD",
    "plugin": "obfs-local",
    "plugin_opts": "obfs=tls;obfs-host=www.bing.com"
}
END
# Generate Shadowsocks URI
SS_URI="ss://$(echo -n aes-256-gcm:$PASSWORD | base64 --wrap=0 | tr +/ -_)@$SERVER_IP:443/?plugin=obfs-local%3bobfs%3dtls%3bobfs-host%3dwww.bing.com"
echo $SS_URI > ~/ss-uri.txt
# Show config to user.
echo "Hello, your Shadowsocks server is ready for use!"
echo "Here is the Shadowsocks URI:"
echo $SS_URI
echo "You can also use the following JSON config:"
cat ~/client.json
echo "Your config is saved at files ~/ss-uri.txt and ~/client.json"