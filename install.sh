#!/bin/bash
#set this to your desired domain
DOMAIN="git.brik.no"

#echo Installing Gitorious and its dependencies..

#subversion will be added as a permanent useflag later on
USE="subversion" emerge git
echo clone the repo
git clone git://github.com/oyvindkinsey/gentoo_gitorious.git /usr/portage/local

echo update /etc/make.conf
echo "PORTDIR_OVERLAY=\"/usr/portage/local\"" >> /etc/make.conf
echo "NGINX_MODULES_HTTP=\"passenger gzip rewrite gzip gzip_static memcached proxy\""

echo link to the provided .use and .keywords files
mkdir /etc/portage/packages.keywords /etc/portage/packages.use
ln -s /usr/portage/local/profiles/package.keywords/gitorious.keywords /etc/portage/package.keywords/
ln -s /usr/portage/local/profiles/package.use/gitorious.use /etc/portage/package.use/

emerge -av dev-db/mysql
echo configure mysql - REMEMBER THE ROOT PASSWORD
emerge --config dev-db/mysql
/etc/init.d/mysql start

echo you will at some point be asked by MySql to supply the root password - do so
DOMAIN="${DOMAIN} emerge gitorious -av

rc-update add mysql default
rc-update add memcached default
rc-update add stompserver default
rc-update add nginx default

/etc/init.d/mysql start
/etc/init.d/memcached start
/etc/init.d/stompserver start
/etc/init.d/nginx start

echo Navigate to ${DOMAIN} to see your freshly installed gitorious!