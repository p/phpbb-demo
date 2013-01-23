#!/bin/sh

qi_repo=/home/pie/apps/git-phpbb/quickinstall
qi_branch=master
phpbb_repo=/home/pie/apps/phpbb/repo
#webroot=/var/www/demo
webroot=/tmp/demo
sudo_php="sudo -u php"

set -e

self_dir=`dirname $0`

$sudo_php rm -rf "$webroot"/*/boards/*
rm -rf "$webroot"/*

for phpbb_branch in develop-olympus develop; do

git cclone "$qi_repo" "$webroot/$phpbb_branch"
git cclone "$phpbb_repo" "$webroot/$phpbb_branch/phpbb"
(cd "$webroot/$phpbb_branch/phpbb" &&
	if test "$phpbb_branch" = develop; then
		git checkout release-3.0.11
	else
		git checkout origin/"$phpbb_branch"
	fi
)
ln -s ../phpbb/phpBB "$webroot/$phpbb_branch/sources/phpBB3"
mkdir -p "$webroot/$phpbb_branch/settings"
cp "$self_dir"/default.cfg "$webroot/$phpbb_branch/settings/"
for dir in boards cache; do
	mkdir -p "$webroot/$phpbb_branch/$dir"
	chmod 0777 "$webroot/$phpbb_branch/$dir"
done

dbname=demo_`echo "$phpbb_branch" |tr - _`
dropdb --if-exists -U qi qi_"$dbname"

python <<-EOT
	import owebunit
	
	s = owebunit.Session()
	s.get('http://demo/$phpbb_branch/')
	s.assert_status(200)
	
	form = s.response.form(id='create-form')
	elements = form.elements.mutable
	elements.set_value('dbname', '$dbname')
	s.post(form.computed_action, body=elements.params.list)
	s.assert_status('redirect')
EOT

if test "$phpbb_branch" = develop; then
	(cd "$webroot/$phpbb_branch/phpbb" &&
		git checkout "$phpbb_branch"
	)
	# need to run under php user account for rm to work later
	$sudo_php rsync -a --no-times "$webroot/$phpbb_branch/phpbb"/phpBB/ "$webroot/$phpbb_branch/boards/$dbname"
	python <<-EOT
		import owebunit
		import re
		
		s = owebunit.Session()
		s.get('http://demo/$phpbb_branch/boards/$dbname/install/database_update.php')
		s.assert_status(200)
		
		assert re.search(r'Result ::.*No errors', s.response.body)
	EOT
fi

$sudo_php rm -rf "$webroot/$phpbb_branch/boards/$dbname/install"

done
