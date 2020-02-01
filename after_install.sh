#!/bin/bash
# Codedeploy doesn't preserve symlinks.
# pm2 binary doesn't work unless it's a symlink to the node_modules/pm2 dir.
# So, make pm2 binary a symlink:
rm ./node_modules/.bin/pm2
ln -s ./node_modules/pm2/bin/pm2 ./node_modules/.bin/pm2
