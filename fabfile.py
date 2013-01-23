from fabric.api import *
import time, os.path

env.shell = '$SHELL -c'

env.app = 'demo'
env.repo_url = 'git@github.com:p/phpbb-demo.git'
env.user = 'deploy'
env.hosts = ['vps.hxr.me']
env.repo_path = '/home/%s/repo' % env.user
env.webroot_path = '/home/%s/webroot' % env.user

def chain_commands(commands):
    chained = ' && '.join(cmd.strip() for cmd in commands)
    return chained

def setup():
    put('prepare.sh', '.')
    put('requirements.txt', '.')
    put('php-fpm.conf', '.')
    put('php.ini', '.')
    put('demo.nginx.conf', '.')
    run('sudo sh `pwd`/prepare.sh')

def update():
    put('install.sh', '.')
    put('vps.cfg', '.')
    put('default.cfg', '.')
    run('sh -x `pwd`/install.sh `pwd`/vps.cfg')

def build():
    put('build.sh', '.')
    run('sh build.sh')

def restart():
    run('sudo pkill php-fpm')
    run('sudo /opt/php55/sbin/php-fpm -y /etc/php55/php-fpm.conf')
    run('sudo /etc/init.d/apache2 stop')
    run('sudo /etc/init.d/nginx stop')
    run('sudo /etc/init.d/nginx start')
