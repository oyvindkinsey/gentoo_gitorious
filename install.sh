#!/bin/bash
#
# NOTE: This script is only if you want an *almost* fully automated setup. 
#

mkdir /etc/portage

#set the needed use flags
echo "dev-vcs/git -perl" >> /etc/portage/package.use

emerge git

echo cloning the repo
git clone git://github.com/oyvindkinsey/gentoo_gitorious.git /usr/portage/local

if [ "$?" -ne "0" ]; then
  exit 1
fi

echo update /etc/make.conf
echo "PORTDIR_OVERLAY=\"/usr/portage/local\"" >> /etc/make.conf

emerge gitorious

if [ "$?" -ne "0" ]; then
  exit 1
fi

emerge --config dev-db/mysql
if [ "$?" -ne "0" ]; then
  exit 1
fi

/etc/init.d/mysql start

emerge --config gitorious
if [ "$?" -ne "0" ]; then
  exit 1
fi

rc-update add mysql default
rc-update add memcached default
rc-update add stompserver default
rc-update add gitorious default
rc-update add nginx default
rc-update add gitorious-poller default
rc-update add gitorious-git-daemon default

/etc/init.d/mysql start
/etc/init.d/memcached start
/etc/init.d/stompserver start
/etc/init.d/gitorious start
/etc/init.d/nginx start
/etc/init.d/gitorious-poller start
/etc/init.d/gitorious-git-daemon start


echo Navigate to ${DOMAIN} to see your freshly installed gitorious!
