#!/usr/bin/env bash
#
# Bootstrap commands to run as root in the new VM, which are not already in
# the rails image.  For example, if you have an application specific RPM to
# install, do it here.

# install dependencies
yum install --assumeyes epel-release
yum install --assumeyes mariadb-server mariadb-devel mariadb curl nodejs

# install dependencies for rvm
yum install -y gcc-c++ patch readline readline-devel zlib zlib-devel libyaml-devel libffi-devel openssl-devel make bzip2 autoconf automake libtool bison iconv-devel sqlite-devel

# enable mariadb and start it now
systemctl enable mariadb --now

# create a dev and test user
mysql <<EOF
CREATE DATABASE myapp_dev CHARACTER SET utf8;
CREATE USER 'myapp_dev'@'localhost' IDENTIFIED BY 'myapp_dev';
GRANT ALL PRIVILEGES ON myapp_dev.* TO 'myapp_dev'@'localhost';
CREATE DATABASE myapp_test CHARACTER SET utf8;
CREATE USER 'myapp_test'@'localhost' IDENTIFIED BY 'myapp_test';
GRANT ALL PRIVILEGES ON myapp_test.* TO 'myapp_test'@'localhost';
quit
EOF
