set up portage
-------------
    mkdir /etc/portage

    #set the needed use flags
    echo "www-servers/nginx nginx_modules_http_passenger nginx_modules_http_proxy nginx_modules_http_rewrite nginx_modules_http_gzip" >> /etc/portage/package.use
    echo "dev-vcs/git -perl" >> /etc/portage/package.use


    #clone the repo
    git clone git://github.com/oyvindkinsey/gentoo_gitorious.git /usr/portage/local

    #update /etc/make.conf
    echo "PORTDIR_OVERLAY=\"/usr/portage/local\"" >> /etc/make.conf

    #set the needed keywords
    cat /usr/portage/local/profiles/package.keywords/gitorious.keywords >> /etc/portage/package.keywords

emerge gitorious
----------------
    emerge gitorious -av

configure gitorious
------------------
    emerge --config gitorious

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
