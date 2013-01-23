#!/bin/sh

php55_url="http://downloads.php.net/dsp/php-5.5.0alpha4.tar.bz2"
cache=$HOME
prefix_base=/opt

set -e

dl() {
	url="$1"
	basename=`basename "$url"`
	if ! test -f "$cache/$basename"; then
		curl -o "$cache/$basename" "$php55_url" || {
			rv=$?
			rm -f "$cache/$basename"
			return $rv
		}
	fi
}

build55() {
	rm -rf /tmp/build
	mkdir /tmp/build
	cd /tmp/build
	dl "$php55_url"
	tar xf "$cache"/`basename "$php55_url"`
	cd php-5.5*
	prefix="$prefix_base"/php55
	./configure --prefix="$prefix" --enable-fpm \
		--with-config-file-path=/etc/php55 \
		--with-config-file-scan-dir=/etc/php55/php.ini.d
	make
	sudo make install
}

sudo apt-get install -y libxml2-dev

build55
