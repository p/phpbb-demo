#!/usr/bin/env python

import re

servers = ['reactor', 'vps']

for server in servers:
    with open('%s.cfg' % server) as f:
        config_lines = f.readlines()
    
    with open('qi.cfg.in') as f:
        qi_config = f.read()
    
    config_map = {}
    for line in config_lines:
        key, value = line.split('=', 2)
        value = re.sub(r'^([\'"])(.*)\1$', r'\2', value)
        qi_config = qi_config.replace('$%s' % key, value)
        config_map[key] = value
    
    if 'pg_password' in config_map:
        if config_map['pg_password']:
            qi_config = qi_config.replace('no_dbpasswd=1', 'no_dbpasswd=0')
        else:
            qi_config = qi_config.replace('no_dbpasswd=0', 'no_dbpasswd=1')
    
    with open('qi.%s.cfg' % server, 'w') as f:
        f.write(qi_config)
