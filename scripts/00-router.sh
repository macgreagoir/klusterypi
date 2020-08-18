#!/bin/bash
# Configure the klusterypi router machine.
#
# This is idempotent and should be safe to rerun to enforce state.

set -e 

[[ $EUID -eq 0 ]] || {
  echo "This script must be run as root" 1>&2
  exit 1
}

# $KLUSTERY is my parent dir.
KLUSTERY=$(cd $(dirname ${BASH_SOURCE[0]})/..; pwd)

# Assign the require vars.
source $KLUSTERY/secrets/config.sh || exit $?
: ${WLAN?} ${NETADDR?} ${NETMASKC?} ${NETMASKQ?} \
  ${EXTERNAL_IFACE} \
  ${PIDOMAIN} ${PIHOST} ${NODE0_MAC} ${NODE1_MAC} ${NODE2_MAC} \
  ${COUNTRY} ${SSID} ${PASSPHR}

# Assumes Raspberry OS
DEBIAN_FRONTEND=noninteractive apt -y install \
  dnsmasq \
  hostapd \
  iptables-persistent \
  netfilter-persistent \
  vim

# Configure networking
# https://www.raspberrypi.org/documentation/configuration/wireless/access-point-routed.md
# * wired port connects to the external (home) router 
# * klusterypi router hosts a wireless network for the cluster and NATs externally

# Enable hostapd (wifi access point)
systemctl unmask hostapd
systemctl enable hostapd


# Bind a static IP addr to the klusterypi wireless network interface.
grep ^interface\ $WLAN || {
  cat >> /etc/dhcpcd.conf <<DHCP
interface $WLAN
    static ip_address=${NETADDR}.1/${NETMASKC}
    nohook wpa_supplicant
DHCP
}

# Allow IPv4 routing between interfaces.
ROUTED_CONF=/etc/sysctl.d/routed-ap.conf
[[ -f $ROUTED_CONF ]] && echo $ROUTED_CONF already exists || {
  cat > $ROUTED_CONF <<RCFG
# Enable IPv4 routing
net.ipv4.ip_forward=1
RCFG
}

# NAT the klusterypi network.
iptables -t nat -L | grep MASQUERADE\ *all\ *.*anywhere || {
  iptables -t nat -A POSTROUTING -o $EXTERNAL_IFACE -j MASQUERADE
  netfilter-persistent save
}

# Configure DHCP for the klusterypi network.
# TODO This could programmatically allow for other than three nodes.
DM_CONF=/etc/dnsmasq.conf

grep $NETADDR $DM_CONF || {
  [[ ! -f $DM_CONF ]] || mv $DM_CONF ${DM_CONF}.orig
  cat > $DM_CONF <<DMCFG
# DHCP interface
interface=$WLAN
# DHCP Pool
# dhcp-range=192.168.1.11,192.168.1.30,255.255.255.0,24h
dhcp-range=${NETADDR}.${MASTER_IP},${NETADDR}.$((MASTER_IP+19)),${NETMASKQ},24h
# klusterypi DNS domain
domain=$PIDOMAIN
# klusterypi router hostname
address=/${PIHOST}.${PIDOMAIN}/${NETADDR}.1

# Reserved addrs for cluster nodes
dhcp-host=${MASTER_MAC},${NETADDR}.${MASTER_IP}
dhcp-host=${NODE0_MAC},${NETADDR}.${NODE0_IP}
dhcp-host=${NODE1_MAC},${NETADDR}.${NODE1_IP}
DMCFG
}

# Ensure wifi radio is not blocked.
rfkill unblock wlan

# Configure and enable the clueterypi wifi network.
HAPD_CONF=/etc/hostapd/hostapd.conf

[[ -f $HAPD_CONF ]] && echo $HAPD_CONF already exists || {
  cat > $HAPD_CONF << HCFG
country_code=$COUNTRY
interface=$WLAN
ssid=$SSID
hw_mode=g
channel=7
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=$PASSPHR
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
HCFG

  systemctl restart hostapd
}

# TODO set passwords and ssh keys

