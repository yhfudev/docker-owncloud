#ARG MYARCH
FROM FROM yhfudev/docker-lamp
MAINTAINER yhfu <yhfudev@gmail.com>


# Report issues here: https://github.com/l3iggs/docker-owncloud/issues
# Say thanks by adding a star or a comment here: https://registry.hub.docker.com/u/l3iggs/owncloud/

# upldate package list
RUN pacman -Syy

# set environmnt variable defaults
ENV REGENERATE_SSL_CERT false
ENV START_APACHE true
ENV START_MYSQL true
ENV MAX_UPLOAD_SIZE 30G
ENV TARGET_SUBDIR owncloud
ENV OC_VERSION '*'

# remove info.php
RUN rm -f /srv/http/info.php

# sudo -- to to run cron as HTTP
# smbclient -- to mount SAMBA shares
# ffmpeg -- for video file previews
# libreoffice-fresh -- for document previews
RUN pacman -Suy --noconfirm --needed sudo smbclient ffmpeg libreoffice-fresh php-ldap

# enable ldap in php
RUN sudo sed -i 's,;extension=ldap.so,extension=ldap.so,g' /etc/php/php.ini

# Install owncloud
RUN pacman -Sw --noconfirm --needed owncloud
RUN pacman -U --noconfirm --needed /var/cache/pacman/pkg/owncloud-${OC_VERSION}-any.pkg.tar.xz

# add our custom config.php
ADD configs/oc-config.php /usr/share/webapps/owncloud/config/config.php

# fixup the permissions (because appairently the package maintainer can't get it right)
ADD fixPerms.sh /root/fixPerms.sh
RUN chmod +x /root/fixPerms.sh
RUN /root/fixPerms.sh

# Install owncloud addons
RUN pacman -S --noconfirm --needed \
    owncloud-app-bookmarks \
    owncloud-app-calendar \
    owncloud-app-contacts \
    owncloud-app-documents \
    owncloud-app-gallery

# disable Apache's dav in favor of the dav built into OC
RUN sed -e 's,^DAVLockDB /home/httpd/DAV/DAVLock,#&,g' \
        -e 's,^LoadModule dav_module modules/mod_dav.so,#&,g' \
        -e 's,^LoadModule dav_fs_module modules/mod_dav_fs.so,#&,g' \
        -e 's,^LoadModule dav_lock_module modules/mod_dav_lock.so,#&,g' \
        -i /etc/httpd/conf/httpd.conf

# enable large file uploads
RUN sed -e "s,php_value upload_max_filesize 513M,php_value upload_max_filesize ${MAX_UPLOAD_SIZE},g" \
        -e "s,php_value post_max_size 513M,php_value post_max_size ${MAX_UPLOAD_SIZE},g" \
        -e 's,<IfModule mod_php5.c>,<IfModule mod_php5.c>\nphp_value output_buffering Off,g' \
        -i /usr/share/webapps/owncloud/.htaccess

# set up PHP for owncloud
# 1. fixes issue with config not editable and occ errors (Issue #44)
# 2. needed for cron / occ (Issue #42)
RUN sed \
    -e 's|open_basedir = /srv/http/:/home/:/tmp/:/usr/share/pear/:/usr/share/webapps/|open_basedir = /srv/http/:/home/:/tmp/:/usr/share/pear/:/usr/share/webapps/:/etc/webapps/|g' \
    -e 's/;extension=posix.so/extension=posix.so/g' \
    -i /etc/php/php.ini

# setup Apache for owncloud
RUN cp /etc/webapps/owncloud/apache.example.conf /etc/httpd/conf/extra/owncloud.conf \
 && sed -e '/<VirtualHost/,/<\/VirtualHost>/d' \
        -e 's,Alias /owncloud /usr/share/webapps/owncloud/,Alias /${TARGET_SUBDIR} /usr/share/webapps/owncloud/,g' \
        -e '/<Directory \/usr\/share\/webapps\/owncloud\/>/a Header always add Strict-Transport-Security "max-age=15768000; includeSubDomains; preload"' \
        -e 's,php_admin_value open_basedir "[^"]*,&:/dev/urandom,g' \
        -i /etc/httpd/conf/extra/owncloud.conf \
 && sed -i '$a Include conf/extra/owncloud.conf' /etc/httpd/conf/httpd.conf \
 && chown -R http:http /usr/share/webapps/owncloud/

# expose some important directories as volumes
VOLUME ["/usr/share/webapps/owncloud/data"]
VOLUME ["/etc/webapps/owncloud/config"]
VOLUME ["/usr/share/webapps/owncloud/apps"]

# place your ssl cert files in here. name them server.key and server.crt
VOLUME ["/https"]

# Enable cron (Issue #42)
RUN pacman -S --noconfirm --needed cronie \
 && systemctl enable cronie.service
ADD configs/cron.conf /etc/oc-cron.conf
RUN crontab /etc/oc-cron.conf \
 && systemctl start cronie.service; exit 0 # force success due to issue with cronie start https://goo.gl/DcGGb

USER docker
RUN yaourt -Syyua --noconfirm --needed \
    owncloud-app-mozilla_sync \
    owncloud-app-notes-git \
    owncloud-app-news-git
USER root

# start servers
CMD ["/root/startServers.sh"]
