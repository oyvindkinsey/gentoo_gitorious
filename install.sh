#!/bin/bash
#
# NOTE: This script is only if you want an *almost* fully automated setup. 
#

DOMAIN=`hostname -f`
echo "Installing gitorious on domain: ${DOMAIN}"

mkdir /etc/portage

#set the needed use flags
echo "dev-vcs/git -perl" >> /etc/portage/package.use
echo "www-servers/nginx nginx_modules_http_passenger nginx_modules_http_proxy nginx_modules_http_rewrite nginx_modules_http_gzip" >> /etc/portage/package.use

#set the needed keywords
cat /usr/portage/local/profiles/package.keywords/gitorious.keywords >> /etc/portage/package.keywords

emerge git

echo cloning the repo
git clone git://github.com/oyvindkinsey/gentoo_gitorious.git /usr/portage/local

if [ "$?" -ne "0" ]; then
  exit 1
fi

echo update /etc/make.conf
echo "PORTDIR_OVERLAY=\"/usr/portage/local\"" >> /etc/make.conf

DOMAIN="${DOMAIN}" emerge gitorious

if [ "$?" -ne "0" ]; then
  exit 1
fi

rc-update add mysql default
rc-update add memcached default
rc-update add stompserver default
rc-update add nginx default
rc-update add gitorious-poller default
rc-update add gitorious-git-daemon default

/etc/init.d/mysql start
/etc/init.d/memcached start
/etc/init.d/stompserver start
/etc/init.d/nginx start
/etc/init.d/gitorious-poller start
/etc/init.d/gitorious-git-daemon start


echo Navigate to ${DOMAIN} to see your freshly installed gitorious!
