#!/bin/sh

set -e

if ! echo "$0" |grep -q /; then
	echo "Please invoke with a path" 1>&2
	exit 10
fi

self_dir=`dirname $0`

branch=
server=
while getopts b:c: option; do
	case $option in
	b)
		branch="$OPTARG"
		;;
	c)
		server="$OPTARG"
		;;
	*)
		echo "Bad option $option" 1>&2
		exit 11
		;;
	esac
done
shift $(($OPTIND - 1))

if test -z "$server"; then
	echo "Server option was not set" 1>&2
	exit 11
fi

. "$self_dir/$server".cfg

test -n "$webroot" || {
	echo "webroot must be set" 1>&2
	exit 11
}

name="$1"
if test -z "$name"; then
	echo "name argument not given" 1>&2
	exit 11
fi

if test -n "$branch"; then
	phpbb_branch="$branch"
else
	phpbb_branch="$name"
fi

echo "$phpbb_branch" |grep -q :
ghuser=`echo "$phpbb_branch" |sed -e 's/:.*//'`
ghbranch=`echo "$phpbb_branch" |sed -e 's/.*://'`

usable_identifier() {
	echo "$1" |sed -e s/'[^a-zA-Z0-9]/_/g'
}

top_dir=`usable_identifier "$name"`
dbname=demo_"$top_dir"
top_dir=`echo "$top_dir" |tr _ -`

$sudo_php rm -rf "$webroot/$top_dir"/boards/*
rm -rf "$webroot/$top_dir"

git cclone "$qi_repo" "$webroot/$top_dir"
git cclone git://github.com/"$ghuser"/phpbb3.git "$webroot/$top_dir/phpbb"
cd "$webroot/$top_dir/phpbb" &&
	if test "$ghbranch" = develop; then
		git checkout release-3.0.11
		basebranch=develop
	else
		git checkout origin/"$ghbranch"
		if test "$ghbranch" = develop-olympus; then
			basebranch=develop-olympus
		else
			develop_merge_count=`git shortlog |grep "Merge branch 'develop-olympus' into develop" |wc -l`
			if test "$develop_merge_count" -gt 300; then
				git checkout release-3.0.11
				basebranch=develop
			else
				basebranch=develop-olympus
			fi
		fi
	fi
ln -s ../phpbb/phpBB "$webroot/$top_dir/sources/phpBB3"
mkdir -p "$webroot/$top_dir/settings"
cp "$self_dir"/qi."$server".cfg "$webroot/$top_dir/settings/"
for dir in boards cache; do
	mkdir -p "$webroot/$top_dir/$dir"
	chmod 0777 "$webroot/$top_dir/$dir"
done

#dropdb --if-exists -U "$pg_admin_user" qi_"$dbname"
echo "drop database if exists qi_$dbname" |psql -U "$pg_admin_user" postgres

python <<EOT
import owebunit

try:
	s = owebunit.Session()
	s.get('$url/$top_dir/')
	s.assert_status(200)

	form = s.response.form(id='create-form')
	elements = form.elements.mutable
	elements.set_value('dbname', '$dbname')
	s.post(form.computed_action, body=elements.params.list)
	s.assert_status('redirect')
except AssertionError as e:
	print('Board creation failed: %s' % str(e))
	print(s.response.body)
	exit(12)
EOT

if test "$basebranch" = develop; then
	(cd "$webroot/$top_dir/phpbb" &&
		git checkout "$ghbranch"
	)
	# need to run under php user account for rm to work later
	# develop removes some files like search backend bits, therefore
	# --delete and --exclude config.php to go with it
	$sudo_php rsync -a --no-times --exclude /config.php --delete \
		"$webroot/$top_dir/phpbb"/phpBB/ \
		"$webroot/$top_dir/boards/$dbname"
	$sudo_php sh -c "cd $webroot/$top_dir/boards/$dbname && php ../../phpbb/composer.phar install"
	python <<EOT
import owebunit
import re

try:
	s = owebunit.Session()
	s.get('$url/$top_dir/boards/$dbname/install/database_update.php')
	s.assert_status(200)

	assert re.search(r'Result ::.*No errors', s.response.body)
except AssertionError as e:
	print('Database update failed: %s' % str(e))
	print(s.response.body)
	exit(12)
EOT
fi

$sudo_php rm -rf "$webroot/$top_dir/boards/$dbname/install"

mkdir -p "$webroot/index"
ln -nsf "../$top_dir/boards/$dbname" "$webroot/index/`echo "$dbname" |tr _ - |sed -e s/^demo-//`"
