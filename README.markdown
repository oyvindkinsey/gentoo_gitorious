emerge git
---------

    #subversion will be added as a permanent useflag later on
    USE="subversion" emerge git
    #clone the repo
    git clone git://github.com/oyvindkinsey/gentoo_gitorious.git /usr/portage/local

    #update /etc/make.conf
    echo "PORTDIR_OVERLAY=\"/usr/portage/local\"" >> /etc/make.conf
    echo "NGINX_MODULES_HTTP=\"passenger gzip rewrite gzip gzip_static memcached proxy\""

set up portage
-------------
    
    #link to the provided .use and .keywords files
    mkdir /etc/portage/packages.keywords /etc/portage/packages.use
    ln -s /usr/portage/local/profiles/package.keywords/gitorious.keywords /etc/portage/package.keywords/
    ln -s /usr/portage/local/profiles/package.use/gitorious.use /etc/portage/package.use/

emerge
-----

    DOMAIN="git.mydomain.com" emerge gitorious -av

start it up
-----------
    
    rc-update add mysql default
    rc-update add memcached default
    rc-update add stompserver default
    rc-update add nginx default

    /etc/init.d/mysql start
    /etc/init.d/memcached start
    /etc/init.d/stompserver start
    /etc/init.d/nginx start


And your done!
