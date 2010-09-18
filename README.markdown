emerge git
---------

    #subversion will be added as a permanent useflag later on
    USE="subversion" emerge git
    #clone the repo
    git clone git://github.com/oyvindkinsey/portage_overlay.git /usr/portage/local

    #update /etc/make.conf
    echo "PORTDIR_OVERLAY=\"/usr/portage/local\"" >> /etc/make.conf
    echo "NGINX_MODULES_HTTP=\"passenger\""

set up portage
-------------
    
    #link to the provided .use and .keywords files
    mkdir /etc/portage/packages.keywords /etc/portage/packages.use
    ln -s /usr/portage/local/profiles/package.keywords/gitorious.keywords /etc/portage/package.keywords/
    ln -s /usr/portage/local/profiles/package.use/gitorious.use /etc/portage/package.use/

emerge
-----

    emerge gitorious -av

