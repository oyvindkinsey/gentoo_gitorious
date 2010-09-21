# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/www-servers/nginx/nginx-0.7.62.ebuild,v 1.3 2009/09/18 19:22:29 keytoaster Exp $
EAPI=2

DESCRIPTION="Gitorious aims to provide a great way of doing distributed opensource code collaboration."

HOMEPAGE="http://gitorious.org/gitorious"
LICENSE="AGPLv3"
SLOT="0"
KEYWORDS="amd64"

EGIT_REPO_URI="git://gitorious.org/gitorious/mainline.git"
inherit git

DEST_DIR="/var/www/gitorious/site/"
HOME_DIR="/var/www/gitorious"
USER="git"

DEPEND=">=dev-vcs/git-1.6.4.4
	>=app-misc/sphinx-0.9.8
	>=dev-ruby/rails-2.3.5
	>=dev-ruby/chronic-0.2.3
	>=dev-ruby/daemons-1.0.10
	>=dev-ruby/diff-lcs-1.1.2
	>=dev-ruby/echoe-4.0
	>=dev-ruby/eventmachine-0.12.10
	>=dev-ruby/fastthread-1.0.7
	>=dev-ruby/geoip-0.8.6
	>=dev-ruby/highline-1.5.1
	>=dev-ruby/hoe-2.4.0
	>=dev-ruby/macaddr-1.0.0
	>=dev-ruby/mime-types-1.16
	>=dev-ruby/net-scp-1.0.2
	>=dev-ruby/net-ssh-2.0.16
	>=dev-ruby/oniguruma-1.1.0
	>=www-servers/nginx-0.7.65-r1[nginx_modules_http_passenger,nginx_modules_http_proxy,nginx_modules_http_rewrite,nginx_modules_http_gzip]
	>=dev-ruby/json-1.4.3-r1
	>=dev-ruby/rack-1.0.1
	>=dev-ruby/rake-0.8.7
	>=dev-ruby/raspell-1.1
	>=dev-ruby/rdiscount-1.3.1.1
	>=dev-ruby/rmagick-2.12.2
	>=dev-ruby/ruby-openid-2.1.7
	>=dev-ruby/rubyforge-2.0.3
	>=dev-ruby/stompserver-0.9.9
	>=dev-ruby/uuid-2.1.0
	>=dev-ruby/mysql-ruby-2.8
	>=dev-ruby/ruby-yadis-0.3.4
	>=dev-ruby/ruby-hmac-0.3.2
	>=dev-ruby/Ruby-MemCache-0.0.4
	>=net-misc/memcached-1.4.1
	>=dev-db/mysql-5.0"
RDEPEND="${DEPEND}"

pkg_nofetch()
{
	einfo "You need to download http://gitorious.org/gitorious/mainline/archive-tarball/master to ${DISTDIR}/gitorious-master.tar.gz before continuing."
       	einfo "You can use 'wget -O ${DISTDIR}/gitorious-master.tar.gz http://gitorious.org/gitorious/mainline/archive-tarball/master' to do this"
}

pkg_setup() {
	ebegin "Creating gitorious user and group"
	enewgroup ${USER}
	enewuser ${USER} -1 /bin/bash ${HOME_DIR} ${USER}",cron,crontab"
	eend ${?}
}

src_unpack() { 
	git_src_unpack 
}

src_install() {
	insinto "${DEST_DIR}"
	doins -r .
}

pkg_postinst() {
        # replace the default configuration files
        cp "${FILESDIR}"/gitorious.yml "${DEST_DIR}"config/
        cp "${FILESDIR}"/database.yml "${DEST_DIR}"config/
        cp "${FILESDIR}"/broker.yml "${DEST_DIR}"config/
        cp "${FILESDIR}"/environment.rb  "${DEST_DIR}"config/
        cp "${FILESDIR}"/createdb.sql  "${DEST_DIR}"config/
        cp "${FILESDIR}"/production.conf  "${DEST_DIR}"config/ultrasphinx/
        cp -r "${FILESDIR}"/cert /etc/nginx
        cp "${FILESDIR}"/nginx.conf  /etc/nginx/nginx.conf
        cp "${FILESDIR}"/.bashrc /var/www/gitorious
        cp "${FILESDIR}"/gitorious-poller /etc/init.d/
        cp "${FILESDIR}"/gitorious-git-daemon /etc/init.d/
        cp "${FILESDIR}"/run-git-daemon  "${DEST_DIR}"script/run-git-daemon
        chmod -R 770 "${DEST_DIR}"script

        cp "${FILESDIR}"/cookie_secret.sh  "${DEST_DIR}"config/
        cp "${FILESDIR}"/createdb.sql  "${DEST_DIR}"config/

	echo "run 'emerge --config =${CATEGORY}/${PF}' in order to configure the setup"
}

pkg_config() {
        # check if mysql is running and configured
        if ! ps ax | grep -v grep | grep "mysql" > /dev/null; then
                einfo "MySql is not running."
                exit 1
        fi

        # check if mysql is configured
        if [ ! -d "${ROOT}"/var/lib/mysql/mysql ] ; then
                einfo "MySql has not been configured yet - please do so using 'emerge --config dev-db/mysql' and rerun this configuration"
                exit 1
        fi

        # get the domain name
        echo "Please set the wanted domain name for Gitorious:"
        read DOMAIN
        sed -i -e "s~git.localhost~${DOMAIN}~g" "${ROOT}${DEST_DIR}"/config/gitorious.yml
        sed -i -e "s~git.localhost~${DOMAIN}~g" ${ROOT}/etc/nginx/nginx.conf

        echo "Please set the email address that error messages etc should be sent to:"
        read EMAIL
        sed -i -e "s~support@localhost~${EMAIL}~g" "${ROOT}"/var/www/gitorious/site/config/gitorious.yml
        echo "Make sure sendmail is working (check the mailhub setting in /etc/ssmtp/ssmtp.conf if you are using SSMTP)."

        # install the required gems
        cd "${ROOT}${DEST_DIR}"
        RAILS_ENV="production" rake gems:install

        # generate a cookie secret
        "${ROOT}${DEST_DIR}"config/cookie_secret.sh

        # set up the database
        echo "We will now create the needed database and user"
        echo "Please supply your mysql root password at the prompt"
        mysql -uroot -p < "${ROOT}${DEST_DIR}"/config/createdb.sql

        cd "${ROOT}${DEST_DIR}"
        RAILS_ENV="production" rake db:migrate

        # add the crontab which runs ultrasphinx (should be converted to a daemon)
        crontab -u git "${ROOT}${DEST_DIR}"/crontab

        # set up needed directories and files
        mkdir "${ROOT}${HOME_DIR}"/tmp
        mkdir "${ROOT}${HOME_DIR}"/tarballs
        mkdir "${ROOT}${HOME_DIR}"/repositories
        mkdir "${ROOT}${HOME_DIR}"/pids
        mkdir "${ROOT}${HOME_DIR}"/site/tmp/pids
        mkdir "${ROOT}${HOME_DIR}"/.ssh
        touch "${ROOT}${HOME_DIR}"/.ssh/authorized_keys

        RAILS_ENV="production" rake ultrasphinx:configure

        chown -R git:git "${ROOT}${HOME_DIR}"
        chmod 700 "${ROOT}${HOME_DIR}"/.ssh
        chmod 600 "${ROOT}${HOME_DIR}"/.ssh/authorized_keys
        chmod 744 "${ROOT}${HOME_DIR}"/site/data/hooks/pre*
        chmod 744 "${ROOT}${HOME_DIR}"/site/data/hooks/post*

        echo "Services need to be started are: nginx, memcached, stompserver, gitorious-git-daemon and gitorious-poller"

}

