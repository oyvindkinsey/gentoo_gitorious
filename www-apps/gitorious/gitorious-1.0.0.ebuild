# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/www-servers/nginx/nginx-0.7.62.ebuild,v 1.3 2009/09/18 19:22:29 keytoaster Exp $
EAPI=2
inherit eutils 

DESCRIPTION="Gitorious aims to provide a great way of doing distributed opensource code collaboration."

HOMEPAGE="http://gitorious.org/gitorious"
SRC_URI="http://gitorious.org/gitorious/mainline/archive-tarball/master -> gitorious-master.tar.gz"
LICENSE="AGPLv3"
SLOT="0"
KEYWORDS="amd64"

DEST_DIR="/var/www/gitorious/site/"
HOME_DIR="/var/www/gitorious"
USER="git"

DEPEND="dev-vcs/subversion[-dso]
	>=dev-vcs/git-1.6.4.4[subversion]
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
	>=www-servers/nginx-0.7.65-r1
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

pkg_setup() {
	if [[ -z "${DOMAIN}" ]] ; then
		die "Please set DOMAIN"
	fi
	einfo "Installing gitorious for the domain ${DOMAIN}"

	ebegin "Creating gitorious user and group"
	enewgroup ${USER}
	enewuser ${USER} -1 /bin/bash ${HOME_DIR} ${USER}",cron,crontab"
	eend ${?}
}

src_unpack() {
	unpack ${A}
}

src_prepare() {
	mv "${WORKDIR}"/gitorious-mainline/* "${WORKDIR}"
}

src_install() {
	insinto "${DEST_DIR}"
	doins -r .
}

pkg_postinst() {
	cp "${FILESDIR}"/gitorious.yml "${DEST_DIR}"config/
	cp "${FILESDIR}"/database.yml "${DEST_DIR}"config/
	cp "${FILESDIR}"/broker.yml  "${DEST_DIR}"config/
	cp "${FILESDIR}"/environment.rb  "${DEST_DIR}"config/
	cp "${FILESDIR}"/createdb.sql  "${DEST_DIR}"config/
	cp "${FILESDIR}"/production.conf  "${DEST_DIR}"config/ultrasphinx/
	cp -r "${FILESDIR}"/cert /etc/nginx
	cp "${FILESDIR}"/nginx.conf  /etc/nginx/nginx.conf
	cp "${FILESDIR}"/.bashrc /var/www/gitorious
	cp "${FILESDIR}"/gitorious-poller /etc/init.d/
	cp "${FILESDIR}"/gitorious-git-daemon /etc/init.d/
	cp "${FILESDIR}"/poller  "${DEST_DIR}"script/poller
	cp "${FILESDIR}"/run-git-daemon  "${DEST_DIR}"script/run-git-daemon
	
	#set the correct host name
	sed -i -e "s~git.localhost~${DOMAIN}~g" "${DEST_DIR}"config/gitorious.yml
	sed -i -e "s~git.localhost~${DOMAIN}~g" /etc/nginx/nginx.conf

	cd "$(echo gem environment gemdir)"/gems/passenger*
	#build the nginx module
	rake nginx
	cd -

	PASSENGER_ROOT= `passenger-config --root`
	sed -i -e "s~PASSENGER_ROOT~${PASSENGER_ROOT}~g" /etc/nginx/nginx.conf
		
	chmod -R 770 "${DEST_DIR}"script
	
	cd "${DEST_DIR}"
	RAILS_ENV="production" rake gems:install
		
	cp "${FILESDIR}"/cookie_secret.sh  "${DEST_DIR}"config/
	"${DEST_DIR}"config/cookie_secret.sh
		
	echo "We will now create the needed database and user"
	echo "Please supply your mysql root password at the prompt"
	mysql -uroot -p < "${FILESDIR}"/createdb.sql
		
	cd "${DEST_DIR}"
	RAILS_ENV="production" rake db:migrate
	
	crontab -u git "${FILESDIR}"/crontab
	
	mkdir "${HOME_DIR}"/tmp
	mkdir "${HOME_DIR}"/tarballs
	mkdir "${HOME_DIR}"/repositories
	mkdir "${HOME_DIR}"/pids
	mkdir "${HOME_DIR}"/site/tmp/pids
	mkdir "${HOME_DIR}"/.ssh
	touch "${HOME_DIR}"/.ssh/authorized_keys
	
	RAILS_ENV="production" rake ultrasphinx:configure
	
	chown -R git:git "${HOME_DIR}"
	chmod 700 "${HOME_DIR}"/.ssh
	chmod 600 "${HOME_DIR}"/.ssh/authorized_keys
	chmod 744 "${HOME_DIR}"/site/data/hooks/pre*
	chmod 744 "${HOME_DIR}"/site/data/hooks/post*
	
	echo "Services need to be started are: nginx, memcached, stompserver"
	echo "You can either restart or manually start what is in the crontab."
	echo
	echo "You will need to add git.local to /etc/hosts to run as is or create dns entries and edit the gitorious.yml and nginx.conf accordingly"
}

