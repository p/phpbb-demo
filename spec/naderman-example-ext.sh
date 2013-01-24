#!/bin/sh

set -e

self_dir=`dirname $0`

# XXX use argument parsing?

. $self_dir/../"$2".cfg

sh -x $self_dir/../install.sh "$@" -b phpbb:develop naderman-example-ext

cd "$webroot"/index/naderman-example-ext
$sudo_php git clone git://github.com/naderman/phpbb3-example-ext.git \
	"$webroot"/index/naderman-example-ext/ext/naderman/example
