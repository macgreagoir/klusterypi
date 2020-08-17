# KlusteryPi

Deploy a Raspberry Pi 4B cluster with

 * a router hosting a wireless network for the cluster,
 * a k8s master machine, and
 * two k8s nodes


## Prerequisites

You need four Raspberry Pi installed with Raspberry Pi OS and SSH enabled.

_There is no need to limit to four, but this expected in this version._


## Install and Configure

0. Review and edit secrets

 0. `cp secrets/example.sh secrets/config.sh`
 0. Edit `secrets/config.sh` for your network, machines and credentials

1. Install and configure

 1. On the router, run `scripts/00-router.sh.sh`
 1. On the three k8s machines (master and nodes), run `scripts/01-k8s_common.sh`
