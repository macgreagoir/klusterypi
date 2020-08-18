#!/bin/bash
# Example config file on which to base your own.
# `cp example.sh config.sh` and edit config.sh

export WLAN=wlan0
export NETADDR=192.168.1
export NETMASKC=24
export NETMASKQ=255.255.255.0
export EXTERNAL_IFACE=eth0
export PIDOMAIN=example.com
export PIHOST=router
export MASTER_MAC=aa:bb:cc:dd:ee:ff
export MASTER_IP=11
export NODE0_MAC=a0:b1:c2:d3:e4:f5
export NODE0_IP=12
export NODE1_MAC=0a:1b:2c:3d:4e:5f
export NODE1_IP=13
export COUNTRY=IE
export SSID=notanssid
export PASSPHR=notapassphr
export POD_NET_CIDR=10.1.0.0/16
