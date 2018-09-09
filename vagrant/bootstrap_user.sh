#!/usr/bin/env bash
#
# Bootstrap commands to run as the vagrant user

###
# rvm is installed in the base image.  just install the version of ruby used
# by this app, then run bundle install.
###
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
curl -L get.rvm.io | bash -s stable
source ~/.rvm/scripts/rvm
rvm install $(cat /vagrant/.ruby-version) --binary --quiet-curl
rvm use $(cat /vagrant/.ruby-version)
cd /vagrant
gem install bundler
echo "Running bundle install..."
bundle install --quiet

###
# Provision config files.
#
###
echo
echo "Provisioning config files ..."
config_filename_bases=("app" "database" "secrets" "services")
for i in "${config_filename_bases[@]}"
do
  config_filename="/vagrant/config/${i}.yml"
  sample_config_filename="/vagrant/config/${i}_sample.yml"
  if [ -f $config_filename ]; then
    echo "${config_filename} already exists"
  else
    echo "Copying ${sample_config_filename} to ${config_filename}"
    cp $sample_config_filename $config_filename
  fi
done

###
# Setting up database
###
echo
echo "Initializing Database ..."
cd /vagrant
rake db:migrate
