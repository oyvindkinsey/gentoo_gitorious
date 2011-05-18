set up portage
-------------
    mkdir /etc/portage

    #set the needed use flags
    grep -qF 'NGINX_MODULES_HTTP' /etc/make.conf \
    && sed -i -e 's:NGINX_MODULES_HTTP=":NGINX_MODULES_HTTP="\n\tpassenger proxy rewrite gzip :g' /etc/make.conf \
    || echo -e "NGINX_MODULES_HTTP=\"passenger proxy rewrite gzip \\\\\n\t\"" >> /etc/make.conf

    #clone the repo
    mkdir -p /usr/local/overlays
    git clone git://github.com/oyvindkinsey/gentoo_gitorious.git /usr/local/overlays

    #update /etc/make.conf
    grep -qF 'PORTDIR_OVERLAY="' /etc/make.conf \
    && sed -i -e 's:PORTDIR_OVERLAY=":PORTDIR_OVERLAY=" \\\n\t/usr/local/overlays/gentoo_gitorious \\\n:g' /etc/make.conf \
    || echo -e "PORTDIR_OVERLAY=\" \\\\\n\t/usr/local/overlays/gentoo_gitorious \\\\\n\t\"" >> /etc/make.conf

    #set the needed keywords
    test -f /etc/portage/package.keywords \
    && mv /etc/portage/package.keywords /etc/portage/unmod_list \
    && mkdir -p /etc/portage/package.keywords \
    && mv /etc/portage/unmod_list /etc/portage/package.keywords/unmod_list
    mkdir -p /etc/portage/package.keywords
    cp /usr/local/overlays/gentoo_gitorious/profiles/package.keywords/gitorious.keywords /etc/portage/package.keywords/

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
