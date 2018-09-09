#!/usr/bin/env bash
###
# Startup webserver
###
echo
echo "Starting Web Server ..."
# initialize RVM
source /home/vagrant/.bash_profile
cd /vagrant
puma -d

