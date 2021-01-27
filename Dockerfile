FROM php:7-cli-alpine

# only necessary environment variables
ENV IFM_ROOT_DIR="/var/www"    \
    IFM_ROOT_PUBLIC_URL="/www" \
    IFM_TMP_DIR="/tmp"

# add missing extensions and dependencies
RUN apk add --no-cache libbz2 libzip libcap openldap-dev sudo && \
    apk add --no-cache --virtual .php-extension-build-deps bzip2 bzip2-dev libzip-dev && \
    docker-php-ext-install bz2 zip ldap && \
    apk del --no-cache --purge .php-extension-build-deps

# allow php binary to bind ports <1000, even if $USER != root
RUN /usr/sbin/setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/php

# remove unnecessary users
RUN deluser xfs && \
    deluser www-data

# sudo: workaround for https://bugzilla.redhat.com/show_bug.cgi?id=1773148
RUN echo "Set disable_coredump false" > /etc/sudo.conf

# prepare files
RUN rm -rf /var/www/html && \
    mkdir -p /usr/local/share/webapps/ifm && \
    chown -R 33:33 /var/www && \
    ln -s /var/www /usr/local/share/webapps/ifm/www && \
    mkdir -p /usr/src/ifm
COPY / /usr/src/ifm/
RUN /usr/src/ifm/compiler.php --languages=all && \
    cp /usr/src/ifm/dist/ifm.php /usr/local/share/webapps/ifm/index.php && \
    cp /usr/src/ifm/docker/php.ini /usr/local/share/webapps/ifm/ && \
    rm -rf /usr/src/ifm

COPY docker/docker-startup.sh /usr/local/bin

# start php server
WORKDIR /usr/local/share/webapps/ifm
EXPOSE 80
CMD /usr/local/bin/docker-startup.sh
