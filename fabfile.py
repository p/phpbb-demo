from fabric.api import *
import time, os.path

env.shell = '$SHELL -c'

env.app = 'demo'
env.repo_url = 'git://github.com/ur/phpbb-demo-build.git'
env.user = 'deploy'
env.hosts = ['vps.hxr.me']
env.repo_path = '/home/%s/repo' % env.user
env.webroot_path = '/home/%s/webroot' % env.user

def chain_commands(commands):
    chained = ' && '.join(cmd.strip() for cmd in commands)
    return chained

def update_repo():
    run(chain_commands([
        'test -d phpbb-demo || git clone %s phpbb-demo' % env.repo_url,
        'cd phpbb-demo && git fetch origin && git reset --hard origin/master',
    ]))

def setup():
    update_repo()
    run('sudo sh `pwd`/phpbb-demo/prepare.sh')

def update():
    update_repo()
    run('sh -x `pwd`/phpbb-demo/install.sh vps')

def build():
    update_repo()
    run('sh `pwd`/phpbb-demo/build.sh')

def restart():
    run('sudo /etc/init.d/apache2 restart')
    #run('sudo pkill php-fpm')
    #run('sudo /opt/php55/sbin/php-fpm -y /etc/php55/php-fpm.conf')
    #run('sudo /etc/init.d/nginx restart')
