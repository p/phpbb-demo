# phpBB Demo Site

A collection of scripts and tools to install and maintain demo phpBB
installations.

## View In Action

- develop-olympus (upcoming 3.0.x): http://olympus.demo.hxr.me/
- develop (upcoming 3.1.0): http://ascraeus.demo.hxr.me/

## Outline

Basically:

- Pull [QuickInstall](https://github.com/phpbb/quickinstall) source.
- Apply a pre-built configuration file to it.
- Get QuickInstall to install phpBB.
- In case of develop (3.1), use database updater to update to the develop
tree as QI cannot install 3.1 directly.

This repository also contains the server configuration. The ultimate
deployment target is a rebuildable VPS running Debian.

## Using

You need [buildploy](https://github.com/p/buildploy) and
[Fabric](http://fabfile.org/) locally for building and deploying.

To build:

	buildploy buildploy.yml

To deploy:

	# (execute pre-setup in prepare.sh on the server)
	
	# configure server
	fab setup
	
	# restart apache
	fab restart
	
	# install/update demo boards
	fab update

## TODO

Lots. See the TODO file.

## License

Released under the 2 clause BSD license.
