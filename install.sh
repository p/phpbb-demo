#!/bin/sh

set -e

if ! echo "$0" |grep -q /; then
	echo "Please invoke with a path" 1>&2
	exit 10
fi

self_dir=`dirname $0`
server="$1"

. "$self_dir/$server".cfg

test -n "$webroot" || {
	echo "webroot must be set" 1>&2
	exit 11
}

#for phpbb_branch in phpbb:develop; do
for phpbb_branch in phpbb:develop-olympus phpbb:develop; do
#for phpbb_branch in nextgen666:develop; do

ghuser=`echo "$phpbb_branch" |sed -e 's/:.*//'`
ghbranch=`echo "$phpbb_branch" |sed -e 's/.*://'`

$sudo_php rm -rf "$webroot/$phpbb_branch"/boards/*
rm -rf "$webroot/$phpbb_branch"

git cclone "$qi_repo" "$webroot/$phpbb_branch"
git cclone git://github.com/"$ghuser"/phpbb3.git "$webroot/$phpbb_branch/phpbb"
cd "$webroot/$phpbb_branch/phpbb" &&
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
ln -s ../phpbb/phpBB "$webroot/$phpbb_branch/sources/phpBB3"
mkdir -p "$webroot/$phpbb_branch/settings"
cp "$self_dir"/qi."$server".cfg "$webroot/$phpbb_branch/settings/"
for dir in boards cache; do
	mkdir -p "$webroot/$phpbb_branch/$dir"
	chmod 0777 "$webroot/$phpbb_branch/$dir"
done

dbname=demo_`echo "$phpbb_branch" |tr :- _`
#dropdb --if-exists -U "$pg_admin_user" qi_"$dbname"
echo "drop database if exists qi_$dbname" |psql -U "$pg_admin_user" postgres

python <<EOT
import owebunit

try:
	s = owebunit.Session()
	s.get('$url/$phpbb_branch/')
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
	(cd "$webroot/$phpbb_branch/phpbb" &&
		git checkout "$ghbranch"
	)
	# need to run under php user account for rm to work later
	# develop removes some files like search backend bits, therefore
	# --delete and --exclude config.php to go with it
	$sudo_php rsync -a --no-times --exclude /config.php --delete \
		"$webroot/$phpbb_branch/phpbb"/phpBB/ \
		"$webroot/$phpbb_branch/boards/$dbname"
	$sudo_php sh -c "cd $webroot/$phpbb_branch/boards/$dbname && php ../../phpbb/composer.phar install"
	python <<EOT
import owebunit
import re

try:
	s = owebunit.Session()
	s.get('$url/$phpbb_branch/boards/$dbname/install/database_update.php')
	s.assert_status(200)

	assert re.search(r'Result ::.*No errors', s.response.body)
except AssertionError as e:
	print('Database update failed: %s' % str(e))
	print(s.response.body)
	exit(12)
EOT
fi

$sudo_php rm -rf "$webroot/$phpbb_branch/boards/$dbname/install"

done
