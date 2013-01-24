#!/bin/sh

# pre-setup:

if false; then

apt-get install -y zsh

usermod deploy >/dev/null 2>&1
if test $? eq 6; then
	useradd -m -s /bin/zsh deploy
fi
if ! test -f .zshenv || ! grep -q 'export EDITOR=vi' .zshenv; then
	echo 'export EDITOR=vi' >>.zshenv
fi
echo 'deploy ALL=(ALL) NOPASSWD: ALL' >/etc/sudoers.d/phpbb-demo-deploy
chmod 0440 /etc/sudoers.d/phpbb-demo-deploy

su - deploy -c '
mkdir -p .ssh && chmod 0700 .ssh && \
touch .ssh/authorized_keys && chmod 0600 .ssh/authorized_keys
'

fi

if test `id -u` != 0; then
	echo "I want to be run as root." 1>&2
	exit 10
fi

set -e

if ! echo "$0" |grep -q /; then
	echo "Please invoke with a path" 1>&2
	exit 10
fi

self_dir=`dirname $0`

#echo 'deb http://backports.debian.org/debian-backports squeeze-backports main' >/etc/apt/sources.list.d/backports.list
#apt-get update

apt-get install -y python-pip python-lxml
# debian php bits
apt-get install -y php5-xdebug
# for building xdebug
#apt-get install -y autoconf
#apt-get install -yt squeeze-backports nginx
pip install git-cachecow
pip install -r "$self_dir"/requirements.txt --upgrade

mkdir -p /var/www/demo
chown deploy:deploy /var/www/demo

su - postgres -c "
echo 'drop user if exists deploy' |psql &&
createuser -sdr deploy
" || true

# drop will fail if any databases have been created
su - postgres -c "
echo 'drop user if exists qi' |psql &&
createuser -SdR qi
" || true

su - postgres -c "
echo \"alter user qi password 'TyijBetja'\" |psql
"

#mkdir -p /etc/php55
#cp "$self_dir"/php-fpm.conf /etc/php55
#cp "$self_dir"/php.ini /etc/php55

#mkdir -p /var/log/php
#chown www-data:www-data /var/log/php

#cp "$self_dir"/demo.nginx.conf /etc/nginx/sites-available/demo
#ln -sf ../sites-available/demo /etc/nginx/sites-enabled/demo

cp "$self_dir"/demo.apache.conf /etc/apache2/sites-available/demo
ln -sf ../sites-available/demo /etc/apache2/sites-enabled/demo

a2enmod vhost_alias
